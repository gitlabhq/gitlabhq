# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        class Engine < Gitlab::Database::Aggregation::Engine
          extend ::Gitlab::Utils::Override

          INNER_QUERY_NAME = 'ch_aggregation_inner_query'
          DEDUP_QUERY_NAME = 'ch_aggregation_dedup_query'
          COLUMN_PREFIX = 'aeq_'

          class << self
            attr_accessor :table_name, :table_primary_key, :table_columns

            def versioned_by(column, deleted_marker: nil)
              if table_columns.blank?
                raise ArgumentError,
                  'Full table columns list must be defined in `table_columns` before calling `versioned_by`'
              end

              @versioning_config = { column: column.to_s, deleted_marker: deleted_marker&.to_s }.freeze
            end

            attr_reader :versioning_config

            def dimensions_mapping
              {
                column: DimensionDefinition,
                date_bucket: DateBucketDimension
              }
            end

            def metrics_mapping
              {
                count: Count,
                mean: Mean,
                rate: Rate,
                quantile: Quantile,
                sum: Sum
              }
            end

            def filters_mapping
              {
                exact_match: ExactMatchFilter,
                range: RangeFilter
              }
            end
          end

          private

          # Example resulting query (no deduplication):
          # SELECT
          #   `ch_aggregation_inner_query`.`aeq_dimension_0` AS aeq_dimension_0,
          #   COUNT(*) AS aeq_metric_0,
          # FROM (
          #   SELECT `agent_platform_sessions`.`flow_type` AS aeq_dimension_0,
          #     anyIfMerge(finished_event_at)-anyIfMerge(created_event_at) AS aeq_metric_0,
          #     `agent_platform_sessions`.`user_id`, ...pk_columns
          #   FROM `agent_platform_sessions`
          #   WHERE ...
          #   GROUP BY ALL) ch_aggregation_inner_query
          # GROUP BY ALL
          #
          # Example resulting query (with deduplication):
          # SELECT
          #   `ch_aggregation_inner_query`.`aeq_dimension_0` AS aeq_dimension_0,
          #   COUNT(*) AS aeq_metric_0
          # FROM (
          #   SELECT `ch_aggregation_dedup_query`.`status` AS aeq_dimension_0,
          #     `ch_aggregation_dedup_query`.`project_id`, ...pk_columns
          #   FROM (
          #     SELECT `ci_finished_builds`.`project_id`, ...pk_columns,
          #       argMax(`ci_finished_builds`.`pipeline_id`, `ci_finished_builds`.`version`) AS pipeline_id,
          #       argMax(`ci_finished_builds`.`deleted`, `ci_finished_builds`.`version`) AS deleted, ...
          #     FROM `ci_finished_builds`
          #     WHERE pk_filters
          #     GROUP BY ALL
          #   ) ch_aggregation_dedup_query
          #   WHERE `ch_aggregation_dedup_query`.`deleted` = 0 AND non_pk_filters
          #   GROUP BY ALL
          # ) ch_aggregation_inner_query
          # GROUP BY ALL
          override :execute_query_plan
          def execute_query_plan(plan)
            base_scope = build_base_query(plan)

            inner_projections, outer_projections = build_select_list_and_aliases(plan, context.merge(scope: base_scope))

            inner_query = base_scope.select(*inner_projections).group(Arel.sql("ALL"))
            inner_query = apply_inner_filters(inner_query, plan)

            query = ::ClickHouse::Client::QueryBuilder.new(inner_query, INNER_QUERY_NAME)
              .select(*outer_projections).group(Arel.sql("ALL"))
            plan.order.each { |order| query = query.order(Arel.sql(column_alias(order)), order.direction) }

            AggregationResult.new(self, plan, query, column_prefix: COLUMN_PREFIX)
          end

          def build_base_query(plan)
            return context[:scope] unless self.class.versioning_config

            dedup_query = build_dedup_subquery

            pk_filters = plan.filters.select { |f| self.class.table_primary_key.include?(f.definition.name.to_s) }
            pk_filters.each { |filter| dedup_query = filter.definition.apply_inner(dedup_query, filter.configuration) }

            ::ClickHouse::Client::QueryBuilder.new(dedup_query, DEDUP_QUERY_NAME)
          end

          def apply_inner_filters(query, plan)
            filters = plan.filters
            # PK filters are applied in deduplication subquery.
            if self.class.versioning_config
              filters = filters.reject { |f| self.class.table_primary_key.include?(f.definition.name.to_s) }
            end

            filters.each { |filter| query = filter.definition.apply_inner(query, filter.configuration) }
            query
          end

          def build_dedup_subquery
            pk_columns = self.class.table_primary_key
            non_pk_columns = self.class.table_columns - pk_columns
            dedup_column = self.class.versioning_config[:column]
            deleted_marker = self.class.versioning_config[:deleted_marker]&.to_s
            source = context[:scope]

            pk_projections = pk_columns.map { |col| source[col] }
            argmax_projections = non_pk_columns.map do |col|
              source.func('argMax', [source[col], source[dedup_column]]).as(col)
            end

            # Ensure deleted_marker is included even if not listed in table_columns
            if deleted_marker && non_pk_columns.exclude?(deleted_marker)
              argmax_projections << source.func(
                'argMax', [source[deleted_marker], source[dedup_column]]
              ).as(deleted_marker)
            end

            query = source.select(*(pk_projections + argmax_projections)).group(Arel.sql("ALL"))
            if deleted_marker
              deleted_argmax = query.func('argMax', [source[deleted_marker], source[dedup_column]])
              query = query.having(deleted_argmax.eq(0))
            end

            query
          end

          def build_select_list_and_aliases(plan, effective_context = context)
            inner_projections_list = []
            outer_projections_list = []

            plan.dimensions.each do |dimension|
              inner_projections, outer_projections = *build_part_selections(dimension, effective_context)
              inner_projections_list += inner_projections
              outer_projections_list += outer_projections
            end

            plan.metrics.each do |metric|
              inner_projections, outer_projections = *build_part_selections(metric, effective_context)
              inner_projections_list += inner_projections
              outer_projections_list += outer_projections
            end

            # fill in primary_key
            inner_projections_list += self.class.table_primary_key.map { |n| effective_context[:scope][n] }

            [inner_projections_list.compact, outer_projections_list.compact]
          end

          def build_part_selections(part, effective_context = context)
            alias_name = column_alias(part)
            inner_context = effective_context.merge(part.name => part.configuration)
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

          def column_alias(plan_part)
            "#{COLUMN_PREFIX}#{plan_part.instance_key}"
          end
        end
      end
    end
  end
end
