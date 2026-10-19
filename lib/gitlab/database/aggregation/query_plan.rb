# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      class QueryPlan
        include ActiveModel::Validations
        include Authorization

        attr_reader :engine, :request

        validate :validate_authorization
        validate :validate_request, unless: :unauthorized?
        validate :validate_parts, unless: :unauthorized?
        validate :validate_instance_keys_uniqueness

        def initialize(engine, request)
          @engine = engine
          @request = request
        end

        def filters
          @filters ||= begin
            definitions = engine.class.filters.index_by(&:identifier)
            request.filters.map do |configuration|
              Filter.new(definitions[configuration[:identifier]], configuration, query_plan: self)
            end
          end
        end

        def dimensions
          @dimensions ||= begin
            definitions = engine.class.dimensions.index_by(&:identifier)
            # Duplicate association definitions without `_id`
            engine.class.dimensions.each do |dimension|
              next unless dimension.association?

              association_identifier = dimension.identifier.to_s.delete_suffix('_id').to_sym
              definitions[association_identifier] = dimension
            end

            request.dimensions.map do |configuration|
              Dimension.new(definitions[configuration[:identifier]], configuration, query_plan: self)
            end
          end
        end

        def metrics
          @metrics ||= requested_metrics - unauthorized_metrics
        end

        def order
          @order ||= request.order.map do |configuration|
            plan_part = orderable_parts.detect { |part| part.matches?(configuration) }

            Order.new(plan_part, configuration, query_plan: self)
          end
        end

        def orderable_parts
          dimensions + metrics
        end

        def parts
          filters + dimensions + metrics + order
        end

        # Lets callers tell an authorization failure apart from other
        # validation errors. Only meaningful after validation.
        def unauthorized?
          errors.of_kind?(:base, :unauthorized)
        end

        private

        # Pruned metrics block execution only when no metrics remain.
        def validate_authorization
          blocking_parts = metrics.empty? ? unauthorized_parts : unauthorized_parts - unauthorized_metrics

          blocking_parts.each do |part|
            errors.add(:base, :unauthorized, message: unauthorized_message(part))
          end
        end

        def requested_metrics
          @requested_metrics ||= begin
            definitions = engine.class.metrics.index_by(&:identifier)
            request.metrics.map do |configuration|
              Metric.new(definitions[configuration[:identifier]], configuration, query_plan: self)
            end
          end
        end

        def validate_parts
          parts.reject(&:valid?).each do |invalid_part|
            errors.merge!(invalid_part.errors)
          end
        end

        def validate_request
          return unless request.metrics.empty?

          errors.add(:metrics,
            s_("AggregationEngine|at least one metric is required"))
        end

        def validate_instance_keys_uniqueness
          return unless errors.empty?

          instance_keys = (dimensions + metrics).group_by(&:instance_key)
          duplicates = instance_keys.select { |_value, occurrences| occurrences.size > 1 }.values.flatten

          return unless duplicates.any?

          identifiers = duplicates.map(&:definition).map(&:identifier).uniq

          placeholder = { identifiers: identifiers.join(', ') }
          errors.add(
            :base,
            format(s_("AggregationEngine|duplicated identifiers found: %{identifiers}"), placeholder)
          )
        end
      end
    end
  end
end
