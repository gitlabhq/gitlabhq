# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      # -- builds ActiveRecord queries
      module ActiveRecord
        class Engine < Gitlab::Database::Aggregation::Engine
          extend ::Gitlab::Utils::Override

          override :metrics_mapping
          def self.metrics_mapping
            {
              count: Count,
              mean: Mean
            }
          end

          override :dimensions_mapping
          def self.dimensions_mapping
            {
              column: Column,
              timestamp_column: TimestampColumn
            }
          end

          private

          override :execute_query_plan
          def execute_query_plan(plan)
            projections, dimension_aliases, metric_aliases = build_select_list_and_aliases(plan)

            relation = context[:scope].select(*projections)
            relation = apply_scope(relation, plan)
            relation = apply_grouping(relation, dimension_aliases)
            relation = apply_order(relation, plan, dimension_aliases, metric_aliases)

            AggregationResult.new(self, plan, relation)
          end

          def run_validations(plan)
            super

            return unless plan.dimensions.size > 2

            errors.add(:dimensions, s_("AggregationEngine|maximum two dimensions are supported"))
          end

          # Returns [projections, dimension_aliases, metric_aliases]
          def build_select_list_and_aliases(plan)
            projections = []
            dimension_aliases = []
            metric_aliases = []

            plan.dimensions.each do |dimension|
              local_ctx = context.merge(dimension.definition.name => dimension.configuration)
              alias_name = dimension.instance_key
              projections << dimension.definition.to_arel(local_ctx).as(alias_name)
              dimension_aliases << alias_name
            end

            plan.metrics.each do |metric|
              local_ctx = context.merge(metric.definition.name => metric.configuration)
              alias_name = metric.instance_key
              projections << metric.definition.to_arel(local_ctx).as(alias_name)
              metric_aliases << alias_name
            end

            [projections, dimension_aliases, metric_aliases]
          end

          def apply_scope(relation, plan)
            plan.parts.reduce(relation) do |rel, part|
              part.definition.apply_scope(rel, context)
            end
          end

          def apply_grouping(relation, dimension_aliases)
            return relation if dimension_aliases.empty?

            relation.group(*dimension_aliases)
          end

          def apply_order(relation, plan, dimension_aliases, metric_aliases)
            orders = plan.order.map do |order_part|
              [order_part.instance_key, order_part.direction]
            end

            if orders.empty?
              relation.order(*(dimension_aliases + metric_aliases))
            else
              relation.order(Hash[orders])
            end
          end
        end
      end
    end
  end
end
