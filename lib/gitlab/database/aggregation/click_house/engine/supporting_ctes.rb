# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        class Engine < Gitlab::Database::Aggregation::Engine
          # Query-time assembly of supporting CTEs declared via the
          # `supporting_cte` DSL: builds each referenced CTE from the filtered
          # base scope and joins it into the inner query.
          module SupportingCtes
            private

            # Each referenced CTE re-aggregates a copy of the filtered base scope per its
            # `join_key`, so it inherits the request's scope, dedup subquery, and row
            # filters by construction. Emitted once per query, no matter how many parts
            # reference it.
            def attach_supporting_ctes(inner_query, base_scope, plan)
              cte_names = referenced_cte_names(plan)
              return inner_query if cte_names.empty?

              cte_scope = apply_inner_filters(base_scope, plan, skip_cte_backed: true)

              cte_names.reduce(inner_query) do |query, name|
                config = self.class.supporting_ctes.fetch(name)
                cte_query = build_supporting_cte(cte_scope, name, config)

                query.with(cte_query.as_cte(name))
                  .joins(Arel::Table.new(name), { config[:join_key] => cte_join_key_alias(name) },
                    type: config[:join_type])
              end
            end

            def build_supporting_cte(cte_scope, name, config)
              cte_query = config[:block].call(cte_scope)

              unless cte_query.is_a?(::ClickHouse::Client::QueryBuilder)
                raise ArgumentError,
                  "supporting CTE `#{name}` block must return a `ClickHouse::Client::QueryBuilder`, " \
                    "got #{cte_query.class}"
              end

              join_key_column = cte_scope.table[config[:join_key]]
              cte_query.select(join_key_column.as(cte_join_key_alias(name))).group(join_key_column)
            end

            # The exposed join key gets a CTE-specific alias so CTE output never duplicates a
            # base column name, which ClickHouse rejects as ambiguous once CTEs are joined in.
            def cte_join_key_alias(name)
              "#{COLUMN_PREFIX}#{name}_key"
            end

            def referenced_cte_names(plan)
              (plan.dimensions + plan.filters + plan.metrics)
                .flat_map { |part| part.definition.ctes }
                .uniq
            end
          end
        end
      end
    end
  end
end
