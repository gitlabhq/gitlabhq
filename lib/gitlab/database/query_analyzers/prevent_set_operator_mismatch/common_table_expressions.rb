# frozen_string_literal: true

# The CTE in a SELECT can reference CTEs defined by the current scope, but also CTEs defined by earlier scopes.
# With the following query as an example:
#
# WITH some_cte AS (select 1)
# SELECT *
# FROM (SELECT * FROM some_cte) subquery
#
# The CTE some_cte is visible from within the subquery scope.
module Gitlab
  module Database
    module QueryAnalyzers
      class PreventSetOperatorMismatch
        class CommonTableExpressions
          class << self
            # Convert CTEs available within this SELECT statement into a set of References.
            #
            # @param [PgQuery::Node] node The PgQuery SELECT statement node containing the CTEs.
            # @param [References] cte_refs Inherited CTEs from scopes that wrap this SELECT statement.
            def references(node, cte_refs)
              return cte_refs if node&.with_clause.nil?

              refs = cte_refs.dup

              node.with_clause.ctes.each do |cte|
                cte_name = name(cte)
                cte_select_stmt = select_stmt(cte)

                # Resolve the CTE type to dynamic/static/error.
                refs[cte_name] = if node.with_clause.recursive
                                   # Recursive CTEs need special handling to avoid infinite loops.
                                   recursive_refs(cte_refs, cte_name, cte_select_stmt)
                                 else
                                   SelectStmt.new(cte_select_stmt, cte_refs).types
                                 end
              end

              refs
            end

            private

            def name(cte)
              cte.common_table_expr.ctename
            end

            def select_stmt(cte)
              cte.common_table_expr.ctequery.select_stmt
            end

            # Return whether the recursive CTE is dynamic/static/error.
            def recursive_refs(cte_refs, cte_name, select_stmt)
              # Resolve the non-recursive term before the recursive term.
              larg_select_stmt = SelectStmt.new(select_stmt.larg, cte_refs)
              larg_type = larg_select_stmt.types
              new_cte_refs = cte_refs.merge({ cte_name => larg_type })

              # Now we can resolve the recursive side.
              rarg_type = SelectStmt.new(select_stmt.rarg, new_cte_refs).types

              final_type = larg_type | rarg_type
              if final_type.count > 1
                final_type | [Type::INVALID]
              else
                final_type
              end
            end
          end
        end
      end
    end
  end
end
