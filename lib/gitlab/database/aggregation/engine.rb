# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      class Engine
        include ActiveModel::Validations

        attr_reader :context

        TYPE_CASTERS = {
          integer: ->(v) { { integer_value: ::ActiveRecord::Type.lookup(:integer).cast(v) } },
          float: ->(v) { { float_value: ::ActiveRecord::Type.lookup(:float).cast(v) } },
          timestamp: ->(v) { { timestamp_value: ::ActiveRecord::Type.lookup(:datetime).cast(v) } },
          string: ->(v) { { string_value: v.to_s } }
        }.freeze

        def self.name
          to_s
        end

        def self.mapping
          raise NotImplementedError
        end

        def self.build(&block)
          klass = Class.new(self)
          klass.class_eval(&block)
          klass
        end

        def self.dimensions(&block)
          return @dimensions unless block

          @dimensions = Dimensions.new(mapping)
          @dimensions.instance_exec(&block)
          @dimensions
        end

        def self.metrics(&block)
          return @metrics unless block

          @metrics = Metrics.new(mapping)
          @metrics.instance_exec(&block)
          @metrics
        end

        def self.to_hash
          {
            metrics: metrics.map(&:to_hash),
            dimensions: dimensions.map(&:to_hash)
          }
        end

        def initialize(context:)
          @context = context
        end

        def execute(request)
          plan = QueryPlan.build(request, self.class)
          run_validations(plan)
          errors.merge!(plan.errors)

          if errors.any?
            ServiceResponse.error(payload: { errors: errors }, message: errors.full_messages.join(', '))
          else
            ServiceResponse.success(payload: { data: execute_query(plan) })
          end
        end

        def execute_query(plan)
          raise NotImplementedError
        end

        private

        # Override this method if you want to add engine-specific validations.
        def run_validations(plan)
          ensure_instance_keys(:dimensions, plan.dimensions)
          ensure_instance_keys(:metrics, plan.metrics)

          return unless plan.metrics.empty?

          errors.add(:metrics, s_("AggregationEngine|at least one metric is required"))
        end

        def to_value_hash(type, value)
          TYPE_CASTERS.fetch(type).call(value)
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
