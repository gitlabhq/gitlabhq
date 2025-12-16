# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        class Engine < Gitlab::Database::Aggregation::Engine
          extend ::Gitlab::Utils::Override

          INNER_QUERY_NAME = 'ch_aggregation_inner_query'

          class << self
            attr_accessor :table_name, :table_primary_key

            def dimensions_mapping
              {
                column: Column
              }
            end

            def metrics_mapping
              {
                count: Count,
                mean: Mean,
                rate: Rate,
                quantile: Quantile
              }
            end
          end

          private

          # Example resulting query
          # SELECT
          #   `ch_aggregation_inner_query`.`dimension_0` AS dimension_0,
          #   COUNT(*) AS metric_0,
          #   countIf(`ch_aggregation_inner_query`.`metric_1_condition` = 1) AS metric_1,
          #   avgIf(`ch_aggregation_inner_query`.`metric_2`, `ch_aggregation_inner_query`.`metric_2_condition` = 1)
          #     AS metric_2
          # FROM (
          #   SELECT `agent_platform_sessions`.`flow_type` AS dimension_0,
          #     anyIfMerge(finished_event_at) IS NOT NULL AS metric_1_condition,
          #     anyIfMerge(finished_event_at)-anyIfMerge(created_event_at) AS metric_2,
          #     anyIfMerge(finished_event_at) IS NOT NULL AS metric_2_condition,
          #     `agent_platform_sessions`.`user_id`,
          #     `agent_platform_sessions`.`namespace_path`,
          #     `agent_platform_sessions`.`session_id`,
          #     `agent_platform_sessions`.`flow_type`
          #   FROM `agent_platform_sessions`
          #   GROUP BY ALL) ch_aggregation_inner_query
          # GROUP BY ALL
          override :execute_query_plan
          def execute_query_plan(plan)
            inner_projections, outer_projections = build_select_list_and_aliases(plan)

            query = context[:scope].select(*inner_projections).group(Arel.sql("ALL"))

            query = ::ClickHouse::Client::QueryBuilder.new(query, INNER_QUERY_NAME)
              .select(*outer_projections).group(Arel.sql("ALL"))

            plan.order.each { |order| query = query.order(Arel.sql(order.instance_key), order.direction) }

            AggregationResult.new(self, plan, query)
          end

          def build_select_list_and_aliases(plan)
            inner_projections_list = []
            outer_projections_list = []

            plan.dimensions.each do |dimension|
              inner_projections, outer_projections = *build_part_selections(dimension)
              inner_projections_list += inner_projections
              outer_projections_list += outer_projections
            end

            plan.metrics.each do |metric|
              inner_projections, outer_projections = *build_part_selections(metric)
              inner_projections_list += inner_projections
              outer_projections_list += outer_projections
            end

            # fill in primary_key
            inner_projections_list += self.class.table_primary_key.map { |n| context[:scope][n] }

            [inner_projections_list.compact, outer_projections_list.compact]
          end

          def build_part_selections(part)
            alias_name = part.instance_key.to_s
            inner_context = context.merge(part.name => part.configuration)
            inner_arel = part.definition.to_inner_arel(inner_context)
            inner_projection = inner_arel&.as(alias_name)

            secondary_alias_name = "#{alias_name}_secondary"
            secondary_projection = part.definition.secondary_arel(inner_context)&.as(secondary_alias_name)

            outer_context = inner_context.merge(inner_query_name: INNER_QUERY_NAME)
            outer_context[:local_alias] = alias_name if inner_projection
            outer_context[:local_secondary_alias] = secondary_alias_name if secondary_projection
            outer_projection = part.definition.to_outer_arel(outer_context).as(alias_name)

            [[inner_projection, secondary_projection], [outer_projection]]
          end
        end
      end
    end
  end
end
