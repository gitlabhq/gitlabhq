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
          SCHEMA_CACHE_DATABASE = :main

          class << self
            attr_reader :table_name, :versioning_config, :table_primary_key

            def table_name=(name)
              table = ::ClickHouse::SchemaCache[SCHEMA_CACHE_DATABASE].table(name)
              unless table
                raise ArgumentError,
                  "Table '#{name}' was not found in the ClickHouse schema cache; " \
                    "ensure the table exists in `db/click_house/schema_cache/#{SCHEMA_CACHE_DATABASE}/`"
              end

              @table_name = name
              @table_primary_key = table.primary_key.filter_map { |part| part.respond_to?(:name) ? part.name : nil }
              apply_replacing_merge_tree_versioning(table)
            end

            def versioned_by(column, deleted_marker: nil)
              @versioning_config = { column: column.to_s, deleted_marker: deleted_marker&.to_s }.freeze
            end

            def table_primary_key=(*columns)
              @table_primary_key = columns.map(&:to_s).freeze
            end

            def table_columns
              schema_cache_table.column_names
            end

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
                sum: Sum,
                retained_count: RetainedCount,
                lagged_count: LaggedCount
              }
            end

            def filters_mapping
              {
                exact_match: ExactMatchFilter,
                range: RangeFilter,
                metric_exact_match: MetricExactMatchFilter,
                metric_range: MetricRangeFilter
              }
            end

            private

            def schema_cache_table
              raise ArgumentError, "`table_name` must be set on #{self}" unless table_name

              ::ClickHouse::SchemaCache[SCHEMA_CACHE_DATABASE].table(table_name)
            end

            def apply_replacing_merge_tree_versioning(table)
              return unless table.engine == 'ReplacingMergeTree'

              version, deleted_marker = table.engine_params
              return unless version

              versioned_by(version, deleted_marker: deleted_marker)
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

            inner_projections, outer_projections, outer_aliases = build_select_list_and_aliases(plan,
              context.merge(scope: base_scope))

            inner_query = base_scope.select(*inner_projections).group(Arel.sql("ALL"))
            inner_query = apply_inner_filters(inner_query, plan)

            query = ::ClickHouse::Client::QueryBuilder.new(inner_query, INNER_QUERY_NAME)
              .select(*outer_projections).group(Arel.sql("ALL"))
            query = apply_outer_filters(query, plan)

            query = wrap_with_window_query(plan, query, outer_aliases) if has_window_metrics?(plan)

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
            filters = plan.filters.reject { |f| f.definition.metric? }
            # PK filters are applied in deduplication subquery.
            if self.class.versioning_config
              filters = filters.reject { |f| self.class.table_primary_key.include?(f.definition.name.to_s) }
            end

            filters.each { |filter| query = filter.definition.apply_inner(query, filter.configuration) }
            query
          end

          def apply_outer_filters(query, plan)
            plan.filters
              .select { |f| f.definition.metric? }
              .reduce(query) do |q, filter|
                metric_part = plan.metrics.find { |m| m.matches?(filter.configuration) }
                filter.definition.apply_outer(q, filter.configuration, Arel.sql(column_alias(metric_part)))
              end
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
            outer_aliases_list = []

            plan.dimensions.each do |dimension|
              inner_projections, outer_projections = *build_part_selections(dimension, effective_context)
              inner_projections_list += inner_projections
              outer_projections_list += outer_projections
              outer_aliases_list << column_alias(dimension)
            end

            plan.metrics.each do |metric|
              inner_projections, outer_projections = *build_part_selections(metric, effective_context)
              inner_projections_list += inner_projections
              outer_projections_list += outer_projections
              outer_aliases_list << column_alias(metric)
            end

            # fill in primary_key
            inner_projections_list += self.class.table_primary_key.map { |n| effective_context[:scope][n] }

            [inner_projections_list.compact, outer_projections_list.compact, outer_aliases_list]
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

          def has_window_metrics?(plan)
            plan.metrics.any? { |metric| metric.definition.requires_window? }
          end

          def wrap_with_window_query(plan, base_query, outer_projection_aliases)
            finalized_query_name = 'ch_aggregation_finalized_query'
            window_query_name = 'ch_aggregation_window_query'

            window_metric_by_alias = plan.metrics
              .select { |m| m.definition.requires_window? }
              .index_by { |m| column_alias(m) }

            finalized_projections = build_layer_projections(outer_projection_aliases,
              window_metric_by_alias) do |part, name|
              part.definition.finalization_sql(name)
            end

            finalized_query = ::ClickHouse::Client::QueryBuilder.new(base_query, finalized_query_name)
              .select(*finalized_projections)

            windowed_projections = build_layer_projections(outer_projection_aliases,
              window_metric_by_alias) do |part, _|
              window_sql_for(part, plan)
            end

            ::ClickHouse::Client::QueryBuilder.new(finalized_query, window_query_name)
              .select(*windowed_projections)
          end

          def build_layer_projections(outer_projection_aliases, window_metric_by_alias)
            outer_projection_aliases.map do |alias_name|
              metric_part = window_metric_by_alias[alias_name]
              if metric_part
                Arel::Nodes::SqlLiteral.new("#{yield(metric_part, alias_name)} AS #{alias_name}")
              else
                Arel::Nodes::SqlLiteral.new(alias_name)
              end
            end
          end

          def window_sql_for(metric_part, plan)
            definition = metric_part.definition
            alias_name = column_alias(metric_part)
            over_alias = dimension_alias_for(definition.over_dimension, plan)

            definition.build_window_sql(context, alias_name, over_alias: over_alias)
          end

          def dimension_alias_for(over_dimension, plan)
            dimension_part = plan.dimensions.find { |d| d.definition.name == over_dimension }

            raise ArgumentError, "Dimension '#{over_dimension}' not found in query plan" unless dimension_part

            column_alias(dimension_part)
          end
        end
      end
    end
  end
end
