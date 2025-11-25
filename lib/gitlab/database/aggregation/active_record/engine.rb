# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ActiveRecord
        # rubocop: disable CodeReuse/ActiveRecord -- builds ActiveRecord queries
        class Engine < Gitlab::Database::Aggregation::Engine
          extend ::Gitlab::Utils::Override

          override :mapping
          def self.mapping
            {
              column: Column,
              timestamp_column: TimestampColumn,
              count: Count,
              mean: Mean
            }
          end

          override :execute_query
          def execute_query(plan)
            projections, dimension_aliases, metric_aliases = build_select_list_and_aliases(plan)

            relation = context[:scope].select(*projections)
            relation = apply_scope(relation, plan)
            relation = apply_grouping(relation, dimension_aliases)
            relation = apply_order(relation, plan, dimension_aliases, metric_aliases)
            relation = relation.limit(1000) # TODO: make this configurable

            rows = relation.to_a
            build_output(rows, plan, dimension_aliases, metric_aliases)
          end

          private

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

          def build_output(rows, plan, dimension_aliases, metric_aliases)
            dimension_index = dimension_aliases.each_with_index.to_h
            metric_index = metric_aliases.each_with_index.to_h

            rows.map do |row|
              dimensions = dimension_aliases.map do |dimension_alias|
                cfg = plan.dimensions[dimension_index[dimension_alias]].definition
                val = row[dimension_alias]
                to_value_hash(cfg.type, cfg.format(val))
              end

              metrics = metric_aliases.map do |metric_alias|
                cfg = plan.metrics[metric_index[metric_alias]].definition
                val = row[metric_alias]
                to_value_hash(cfg.type, cfg.format(val))
              end

              { dimensions: dimensions, metrics: metrics }
            end
          end
          # rubocop: enable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
