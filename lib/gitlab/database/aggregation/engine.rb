# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      class Engine
        include ActiveModel::Validations

        class << self
          def name
            to_s
          end

          def metrics_mapping
            raise NoMethodError
          end

          def dimensions_mapping
            raise NoMethodError
          end

          def build(&block)
            Class.new(self).tap { |klass| klass.class_eval(&block) }
          end

          def dimensions(&block)
            @dimensions ||= []

            return @dimensions unless block

            @dimensions += DefinitionsCollector.new(dimensions_mapping).collect(&block)

            guard_definitions_uniqueness!

            @dimensions
          end

          def metrics(&block)
            @metrics ||= []
            return @metrics unless block

            @metrics += DefinitionsCollector.new(metrics_mapping).collect(&block)

            guard_definitions_uniqueness!

            @metrics
          end

          def to_hash
            {
              metrics: metrics.map(&:to_hash),
              dimensions: dimensions.map(&:to_hash)
            }
          end

          private

          def guard_definitions_uniqueness!
            identifiers = dimensions.map(&:identifier) + metrics.map(&:identifier)
            duplicates = identifiers.group_by(&:itself).select { |_k, v| v.size > 1 }.keys

            return unless duplicates.present?

            raise "Identical engine parts found: #{duplicates.inspect}. Engine parts identifiers must be unique."
          end
        end

        attr_reader :context

        def initialize(context:)
          @context = context
        end

        # @return [Gitlab::Database::Aggregation::AggregationResult]
        def execute(request)
          plan = QueryPlan.build(request, self)
          run_validations(plan)
          errors.merge!(plan.errors)

          if errors.any?
            ServiceResponse.error(payload: { errors: errors }, message: errors.full_messages.join(', '))
          else
            ServiceResponse.success(payload: { data: execute_query_plan(plan) })
          end
        end

        private

        def execute_query_plan(_plan)
          raise NoMethodError
        end

        # Override this method if you want to add engine-specific validations.
        def run_validations(plan)
          ensure_instance_keys(:dimensions, plan.dimensions)
          ensure_instance_keys(:metrics, plan.metrics)

          return unless plan.metrics.empty?

          errors.add(:metrics, s_("AggregationEngine|at least one metric is required"))
        end

        def ensure_instance_keys(error_key, collection)
          instance_keys = collection.group_by(&:instance_key)
          duplicates = instance_keys.select { |_value, occurrences| occurrences.size > 1 }.values

          return unless duplicates.any?

          duplicate = duplicates.first.first

          placeholder = { identifier: duplicate.definition.identifier }
          errors.add(
            error_key,
            format(s_("AggregationEngine|duplicated identifier found: %{identifier}"), placeholder)
          )
        end
      end
    end
  end
end
