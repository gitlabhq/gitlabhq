# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        class Engine < Gitlab::Database::Aggregation::Engine
          # Class-level declaration DSL specific to ClickHouse engines: table
          # configuration, deduplication versioning, and supporting CTEs.
          #
          # rubocop:disable Gitlab/ModuleWithInstanceVariables -- extended into engine
          # classes, so the ivars hold class-level DSL state, not mixin instance state
          module Dsl
            extend ::Gitlab::Utils::Override

            SCHEMA_CACHE_DATABASE = :main

            # Supporting CTEs group the prepared base rows directly by `join_key`, which is
            # only correct when each base row represents one entity. On AggregatingMergeTree
            # tables rows are partial aggregate states and `merge_column:` filters are HAVING
            # clauses over merged states, so grouping by `join_key` would evaluate them once
            # per key instead of once per entity, silently producing wrong per-key summaries.
            SUPPORTED_CTE_TABLE_ENGINES = %w[MergeTree ReplacingMergeTree].freeze
            CTE_NAME_FORMAT = /\A[a-z][a-z0-9_]*\z/
            CTE_JOIN_TYPES = %i[inner outer].freeze

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

            # Declares a per-`join_key` summary query over the engine's own table. The
            # block receives a copy of the prepared base scope (tenant scope, dedup
            # subquery, and row filters applied) and must only add aggregate projections;
            # the framework adds the `join_key` column and `GROUP BY join_key`. Parts
            # reference the summary via `ctes:` and must qualify its columns by name
            # (`<cte_name>.<column>`).
            def supporting_cte(name, join_key:, join_type: :inner, &block)
              name = name.to_sym
              guard_supporting_cte_table_engine!
              guard_supporting_cte_declaration!(name, join_key, join_type, block)

              supporting_ctes[name] = { join_key: join_key.to_s, join_type: join_type, block: block }.freeze
            end

            def supporting_ctes
              @supporting_ctes ||= {}
            end

            override :dimensions
            def dimensions(&block)
              super.tap { |definitions| guard_cte_references!(definitions) if block }
            end

            override :filters
            def filters(&block)
              super.tap { |definitions| guard_cte_references!(definitions) if block }
            end

            override :metrics
            def metrics(&block)
              super.tap { |definitions| guard_cte_references!(definitions) if block }
            end

            private

            def guard_supporting_cte_table_engine!
              table_engine = schema_cache_table.engine
              return if SUPPORTED_CTE_TABLE_ENGINES.include?(table_engine)

              raise ArgumentError,
                "`supporting_cte` is not supported for #{table_engine} tables. " \
                  "Supported table engines: #{SUPPORTED_CTE_TABLE_ENGINES.join(', ')}"
            end

            def guard_supporting_cte_declaration!(name, join_key, join_type, block)
              raise ArgumentError, "`supporting_cte` requires a block" unless block

              unless CTE_NAME_FORMAT.match?(name.to_s)
                raise ArgumentError, "Invalid supporting CTE name `#{name}`: must match #{CTE_NAME_FORMAT.inspect}"
              end

              raise ArgumentError, "Supporting CTE `#{name}` is already declared" if supporting_ctes.key?(name)

              unless table_columns.include?(join_key.to_s)
                raise ArgumentError, "Unknown `join_key` column `#{join_key}` for table `#{table_name}`"
              end

              return if CTE_JOIN_TYPES.include?(join_type)

              raise ArgumentError, "Invalid `join_type` `#{join_type}`: must be one of #{CTE_JOIN_TYPES.inspect}"
            end

            def guard_cte_references!(definitions)
              definitions.each do |definition|
                unknown = definition.ctes - supporting_ctes.keys
                next if unknown.empty?

                raise ArgumentError,
                  "Unknown supporting CTE(s) #{unknown.inspect} referenced by `#{definition.identifier}`. " \
                    "Declare them with `supporting_cte` before referencing."
              end
            end

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
          # rubocop:enable Gitlab/ModuleWithInstanceVariables
        end
      end
    end
  end
end
