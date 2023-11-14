# frozen_string_literal: true

module Gitlab
  module Database
    module QueryAnalyzers
      class PreventSetOperatorMismatch
        # Columns refer to table columns produced by queries and parts of queries.
        # If we have `SELECT namespaces.id` then `id` is a column. But, we can also have
        # `WHERE namespaces.id > 10` and `id` is also a column.
        #
        # In static analysis of a SQL query a column source can be ambiguous.
        # Such as in `SELECT id FROM users, namespaces. In such cases we assume `id` could come from either `users` or
        # `namespaces`.
        class Columns
          class << self
            # Determine the type of each column in the select statement.
            # Returns a Set object containing a Types enum.
            # When an error is found parsing will return immediately.
            def types(select_stmt)
              # Forward through any errors when the column refers to a part of the SQL query that is known to include
              # errors. For example, the column may refer to a column from a CTE that was invalid.
              return Set.new([Type::INVALID]) if References.errors?(select_stmt.all_references)

              types = Set.new

              # Resolve the type of reference for each target in the select statement.
              target_list = select_stmt.node.target_list
              targets = target_list.map(&:res_target)
              targets.each do |target|
                target_type = get_target_type(target, select_stmt)

                # A NULL target is of the form:
                # SELECT NULL::namespaces FROM namespaces
                types += if Targets.null?(target)
                           # Maintain any errors but otherwise ignore this target.
                           target_type & [Type::INVALID]
                         else
                           target_type
                         end
              end

              types
            end

            private

            def get_target_type(target, select_stmt)
              target_ref_names = Targets.reference_names(target, select_stmt)

              resolved_refs = References.resolved(select_stmt.all_references)

              # Cross reference column references with resolved references.
              # A resolved reference is part of a SQL query that we were able to analyze already.
              # A CTE or sub-query would be such a case. The only non-resolvable reference is a table.
              all_resolved = (target_ref_names - resolved_refs.keys).empty?

              # Is this target `*` such as `SELECT *`.
              a_star = Targets.a_star?(target)

              if all_resolved
                # Defer to the reference source types.
                col_refs = resolved_refs.slice(*target_ref_names)
                                        .values
                                        .reduce(:union) || Set.new

                if a_star
                  # When * the target forwards through the types of the references.
                  col_refs
                else
                  # When not * the column is static, but we also forward through any nested errors.
                  (col_refs.to_a & [Type::INVALID]) << Type::STATIC
                end
              elsif a_star
                # This is a * on a table. The * lookup occurs dynamically during query runtime and will
                # change when the table schema changes.
                [Type::DYNAMIC]
              else
                # This references a column on a table or intermediate result set such as:
                # SELECT namespaces.id FROM namespaces
                #
                # or:
                # WITH some_cte AS ( ... ) SELECT some_cte.id FROM some_cte
                [Type::STATIC]
              end
            end
          end
        end
      end
    end
  end
end
