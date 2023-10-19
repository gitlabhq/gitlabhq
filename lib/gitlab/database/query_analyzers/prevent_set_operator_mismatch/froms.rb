# frozen_string_literal: true

module Gitlab
  module Database
    module QueryAnalyzers
      class PreventSetOperatorMismatch
        class Froms
          class << self
            # Parse the FROM part of the SELECT. Construct a mapping of FROM names to their PgQuery node. Recurse any
            # sub-queries and resolve to a Set of dynamic/static/error.
            #
            # Whenever a node is aliased, use the alias name as it's reference and ignore it's original name.
            #
            # For example, given:
            #
            # SELECT id
            # FROM namespaces ns
            #
            # Return a Hash of { 'ns' => NodeObject }
            #
            # @param [PgQuery::Node] node The PgQuery SELECT statement node containing the CTEs.
            # @param [References] cte_refs Inherited CTEs from scopes that wrap this SELECT statement.
            #
            # @return [Hash] name of from references mapped to the node that defines their value, or Set if already
            # resolved.
            def references(node, cte_refs)
              refs = {}

              return refs unless node

              node.from_clause.each do |from|
                range_var = Node.dig(from, :range_var)
                range_sq = Node.dig(from, :range_subselect)

                if range_var
                  # FROM some_table
                  # FROM some_table some_alias
                  refs.merge!(range_var_reference(range_var, cte_refs))
                elsif Node.dig(from, :join_expr)
                  # FROM some_table INNER JOIN other_table
                  range_vars = Node.locate_descendants(from, :range_var)
                  range_vars.each do |range_var|
                    refs.merge!(range_var_reference(range_var, cte_refs))
                  end
                elsif range_sq
                  # FROM (SELECT ...) some_alias
                  select_stmt = Node.dig(range_sq, :subquery, :select_stmt)
                  refs[range_sq.alias.aliasname] = SelectStmt.new(select_stmt, cte_refs).types
                end
              end

              refs
            end

            private

            def range_var_reference(range_var, cte_refs)
              relname = Node.dig(range_var, :alias, :aliasname) || range_var.relname
              reference = cte_refs[range_var.relname] || range_var

              { relname => reference }
            end
          end
        end
      end
    end
  end
end
