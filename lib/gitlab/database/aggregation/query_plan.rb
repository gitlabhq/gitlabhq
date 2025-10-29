# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      class QueryPlan
        include ActiveModel::Validations

        class DimensionPlan
          attr_reader :configuration, :dimension

          def initialize(configuration, dimension)
            @configuration = configuration
            @dimension = dimension
          end
        end

        class MetricPlan
          attr_reader :configuration, :metric

          def initialize(configuration, metric)
            @configuration = configuration
            @metric = metric
          end
        end

        attr_reader :dimensions, :metrics, :order

        def self.build(request, engine)
          configured_dimensions = engine.dimensions.index_by(&:identifier)
          configured_metrics = engine.metrics.index_by(&:identifier)

          plan = new
          request.dimensions.each do |dimension|
            dimension_column_configuration = configured_dimensions[dimension[:identifier]]
            if dimension_column_configuration.nil?
              add_error_for(plan, :dimensions, dimension[:identifier])
              break
            end

            plan.add_dimension(dimension_column_configuration, dimension)
          end

          request.metrics.each do |metric|
            metric_column_configuration = configured_metrics[metric[:identifier]]
            if metric_column_configuration.nil?
              add_error_for(plan, :metrics, metric[:identifier])
              break
            end

            plan.add_metric(metric_column_configuration, metric)
          end

          request.order.each do |order|
            unless configured_dimensions[order[:identifier]] || configured_metrics[order[:identifier]]
              add_error_for(plan, :order, order[:identifier])
              break
            end

            plan.add_order(order)
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

        def add_dimension(configuration, dimension)
          @dimensions << DimensionPlan.new(configuration, dimension)
        end

        def add_metric(configuration, metric)
          @metrics << MetricPlan.new(configuration, metric)
        end

        def add_order(kind)
          @order << kind
        end
      end
    end
  end
end
