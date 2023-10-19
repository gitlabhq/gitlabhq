# frozen_string_literal: true

# Targets refer to SELECT columns but also JOIN fields, etc.
# A target can have a qualifying reference to some other entity like a table or CTE.
module Gitlab
  module Database
    module QueryAnalyzers
      class PreventSetOperatorMismatch
        class Targets
          class << self
            # Return the reference names used by the given target.
            #
            # For example:
            # `SELECT users.id` would return ['users']
            # `SELECT * FROM users, namespaces` would return ['users', 'namespaces']
            def reference_names(target, select_stmt)
              # Parse all targets to determine what is referenced.
              fields = fields(target)
              case fields.count
              when 0
                literal_ref_names(target, select_stmt)
              when 1
                unqualified_ref_names(fields, select_stmt)
              else
                # The target is qualified such as SELECT reference.id
                field_ref = fields[fields.count - 2]
                [field_ref.string.sval]
              end
            end

            # True when `SELECT *`
            def a_star?(target)
              Node.locate_descendant(target, :a_star)
            end

            # Null targets are used to produce "polymorphic" query result sets that can be aggregated through a UNION
            # without having to worry about mismatched columns.
            #
            # A null target would be something like:
            # SELECT NULL::namespaces FROM namespaces
            def null?(target)
              target&.val&.type_cast&.arg&.a_const&.isnull
            end

            private

            def literal_ref_names(target, select_stmt)
              # The target is unqualified and is not part of a column_ref, such as in `SELECT 1`.
              # These include targets like literals, functions, and subselects.
              sub_select_stmt = subselect_select_stmt(target)
              if sub_select_stmt
                name = (target.name.presence || "loc_#{target.location}")
                # The select is anonymous, so we provide a name.
                k = "#{name}_subselect"
                # Force parsing of the select.
                # We don't care about the static/dynamic nature in this case, but we do need to parse for
                # any nested error states.
                sub_select = SelectStmt.new(sub_select_stmt, select_stmt.cte_references)
                select_stmt.all_references[k] = sub_select.types
                [k]
              else
                # TODO we need to parse function references. Assuming no sources for now.
                # https://gitlab.com/gitlab-org/gitlab/-/issues/428102
                []
              end
            end

            def unqualified_ref_names(fields, select_stmt)
              # The target is unqualified, but is part of a column_ref.
              # E.g. `SELECT id FROM namespaces` or `SELECT namespaces FROM namespaces`

              # Otherwise, check all FROM/JOIN/CTE entries.
              field = fields[0]
              field_sval = field&.string&.sval
              if field_sval && select_stmt.all_references.key?(field_sval)
                # SELECT some_table_name
                [field.string.sval]
              else
                # SELECT *
                # SELECT some_column
                select_stmt.all_references.keys
              end
            end

            def fields(target)
              Node.locate_descendants(target, :fields).flatten
            end

            def subselect_select_stmt(target)
              Node.dig(target, :val, :sub_link, :subselect, :select_stmt)
            end
          end
        end
      end
    end
  end
end
