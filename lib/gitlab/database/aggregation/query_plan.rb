# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      class QueryPlan
        include ActiveModel::Validations

        attr_reader :dimensions, :metrics, :order

        class << self
          def build(request, engine)
            engine_definition = engine.class
            plan = new

            dimension_definitions = engine_definition.dimensions.index_by(&:identifier)
            request.dimensions.each do |configuration|
              dimension_definition = dimension_definitions[configuration[:identifier]]
              if dimension_definition.nil?
                add_error_for(plan, :dimensions, configuration[:identifier])
                break
              end

              plan.add_dimension(dimension_definition, configuration)
            end

            metric_definitions = engine_definition.metrics.index_by(&:identifier)
            request.metrics.each do |configuration|
              metric_definition = metric_definitions[configuration[:identifier]]
              if metric_definition.nil?
                add_error_for(plan, :metrics, configuration[:identifier])
                break
              end

              plan.add_metric(metric_definition, configuration)
            end

            request.order.each do |configuration|
              plan_part = plan.orderable_parts.detect do |plan_part|
                configuration.except(:direction) == plan_part.configuration
              end

              unless plan_part
                add_error_for(plan, :order, configuration[:identifier])
                break
              end

              plan.add_order(plan_part, configuration)
            end

            plan
          end

          def add_error_for(plan, object, identifier)
            plan.errors.add(object,
              format(s_("AggregationEngine|the specified identifier is not available: '%{identifier}'"),
                identifier: identifier))
          end
        end

        def initialize
          @dimensions = []
          @metrics = []
          @order = []
        end

        def orderable_parts
          dimensions + metrics
        end

        def parts
          dimensions + metrics + order
        end

        def add_dimension(definition, configuration)
          @dimensions << Dimension.new(definition, configuration)
        end

        def add_metric(definition, configuration)
          @metrics << Metric.new(definition, configuration)
        end

        def add_order(plan_part, configuration)
          @order << Order.new(plan_part, configuration)
        end
      end
    end
  end
end
