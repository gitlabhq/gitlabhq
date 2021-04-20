# frozen_string_literal: true

module Gitlab
  module SQL
    # Class for easily building recursive CTE statements.
    #
    # Example:
    #
    #     cte = RecursiveCTE.new(:my_cte_name)
    #     ns = Arel::Table.new(:namespaces)
    #
    #     cte << Namespace.
    #       where(ns[:parent_id].eq(some_namespace_id))
    #
    #     cte << Namespace.
    #       from([ns, cte.table]).
    #       where(ns[:parent_id].eq(cte.table[:id]))
    #
    #     Namespace.with.
    #       recursive(cte.to_arel).
    #       from(cte.alias_to(ns))
    class RecursiveCTE
      attr_reader :table

      # name - The name of the CTE as a String or Symbol.
      # union_args - The arguments supplied to Gitlab::SQL::Union class when building inner recursive query
      def initialize(name, union_args: {})
        @table = Arel::Table.new(name)
        @queries = []
        @union_args = union_args
      end

      # Adds a query to the body of the CTE.
      #
      # relation - The relation object to add to the body of the CTE.
      def <<(relation)
        @queries << relation
      end

      # Returns the Arel relation for this CTE.
      def to_arel
        sql = Arel::Nodes::SqlLiteral.new(Union.new(@queries, **@union_args).to_sql)

        Arel::Nodes::As.new(table, Arel::Nodes::Grouping.new(sql))
      end

      # Returns an "AS" statement that aliases the CTE name as the given table
      # name. This allows one to trick ActiveRecord into thinking it's selecting
      # from an actual table, when in reality it's selecting from a CTE.
      #
      # alias_table - The Arel table to use as the alias.
      def alias_to(alias_table)
        Arel::Nodes::As.new(table, Arel::Table.new(alias_table.name.tr('.', '_')))
      end

      # Applies the CTE to the given relation, returning a new one that will
      # query from it.
      def apply_to(relation)
        relation.except(:where)
          .with
          .recursive(to_arel)
          .from(alias_to(relation.model.arel_table))
      end
    end
  end
end
