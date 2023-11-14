# frozen_string_literal: true

module Gitlab
  module Database
    module QueryAnalyzers
      class PreventSetOperatorMismatch
        class SelectStmt
          include Gitlab::Utils::StrongMemoize

          attr_reader :node, :cte_references, :all_references

          # @param [PgQuery::SelectStmt] node The PgQuery node of the select statement.
          # @param [Hash] inherited_cte_references CTE References available to the select statement.
          def initialize(node, inherited_cte_references = {})
            @node = node
            @cte_references = CommonTableExpressions.references(node, inherited_cte_references)
            from_references = Froms.references(node, cte_references)
            @all_references = from_references.merge(cte_references)
          end

          # returns Set of Types.
          #
          # STATIC - queries that don't require a database schema lookup. E.g. `SELECT users.id FROM users`
          # DYNAMIC - queries that require a database schema lookup. E.g. `SELECT users.* FROM users`
          # INVALID - set operator queries that mix static and dynamic queries.
          def types
            if set_operator?
              resolve_set_operator_select_types
            else
              resolve_normal_select_types
            end
          end

          private

          # Standard SELECT, not a set operator (UNION/INTERSECT/EXCEPT)
          def resolve_normal_select_types
            # Cross reference resolved sources with what is requested by the SELECT.
            types = Columns.types(self)

            # Mixed dynamic and static queries can be normalized to simply dynamic queries for the purposes of
            # detecting mismatched set operator parts.
            types.delete(Type::STATIC) if types.include?(Type::DYNAMIC)

            types
          end

          # Set operator (UNION/INTERSECT/EXCEPT)
          def resolve_set_operator_select_types
            types = Set.new

            # Recurse each set operator part as a SELECT statement.
            # select statement part => type
            set_operator_parts do |part|
              types += SelectStmt.new(part, cte_references).types
            end

            types << Type::INVALID if types.count > 1

            types
          end

          def set_operator?
            !(node.respond_to?(:op) && node.op == :SETOP_NONE)
          end

          SET_OPERATOR_PART_LOCATIONS = %i[larg rarg].freeze
          private_constant :SET_OPERATOR_PART_LOCATIONS

          def set_operator_parts(&_blk)
            return unless node

            yield node if node.op == :SETOP_NONE
            yield node.larg if node.larg && node.larg.op == :SETOP_NONE
            yield node.rarg if node.rarg && node.rarg.op == :SETOP_NONE
          end
        end
      end
    end
  end
end
