# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      class QueryPlan
        include ActiveModel::Validations

        class Dimension
          attr_reader :definition, :configuration

          def initialize(definition, configuration)
            @definition = definition
            @configuration = configuration
          end

          def instance_key
            definition.instance_key(configuration).to_s
          end
        end

        class Metric
          attr_reader :definition, :configuration

          def initialize(definition, configuration)
            @definition = definition
            @configuration = configuration
          end

          def instance_key
            definition.instance_key(configuration).to_s
          end
        end

        class Order
          attr_reader :plan_part, :configuration

          def initialize(plan_part, configuration)
            @plan_part = plan_part
            @configuration = configuration
          end

          delegate :instance_key, to: :plan_part

          def direction
            configuration[:direction]
          end
        end

        attr_reader :dimensions, :metrics, :order

        def self.build(request, engine)
          dimension_definitions = engine.dimensions.index_by(&:identifier)
          metric_definitions = engine.metrics.index_by(&:identifier)

          plan = new
          request.dimensions.each do |dimension|
            dimension_column_configuration = dimension_definitions[dimension[:identifier]]
            if dimension_column_configuration.nil?
              add_error_for(plan, :dimensions, dimension[:identifier])
              break
            end

            plan.add_dimension(dimension_column_configuration, dimension)
          end

          request.metrics.each do |metric|
            metric_column_configuration = metric_definitions[metric[:identifier]]
            if metric_column_configuration.nil?
              add_error_for(plan, :metrics, metric[:identifier])
              break
            end

            plan.add_metric(metric_column_configuration, metric)
          end

          request.order.each do |configuration|
            plan_part = plan.parts.detect do |plan_part|
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

        def self.add_error_for(plan, object, identifier)
          plan.errors.add(object,
            format(s_("AggregationEngine|the specified identifier is not available: '%{identifier}'"),
              identifier: identifier))
        end

        def initialize
          @dimensions = []
          @metrics = []
          @order = []
        end

        def parts
          dimensions + metrics
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
