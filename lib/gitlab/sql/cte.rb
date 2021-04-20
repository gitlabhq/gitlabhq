# frozen_string_literal: true

module Gitlab
  module SQL
    # Class for easily building CTE statements.
    #
    # Example:
    #
    #     cte = CTE.new(:my_cte_name)
    #     ns = Arel::Table.new(:namespaces)
    #
    #     cte << Namespace.
    #       where(ns[:parent_id].eq(some_namespace_id))
    #
    #     Namespace
    #       with(cte.to_arel).
    #       from(cte.alias_to(ns))
    #
    # To skip materialization of the CTE query by passing materialized: false
    # More context: https://www.postgresql.org/docs/12/queries-with.html
    #
    # cte = CTE.new(:my_cte_name, materialized: false)
    #
    class CTE
      attr_reader :table, :query

      # name - The name of the CTE as a String or Symbol.
      def initialize(name, query, materialized: true)
        @table = Arel::Table.new(name)
        @query = query
        @materialized = materialized
      end

      # Returns the Arel relation for this CTE.
      def to_arel
        sql = Arel::Nodes::SqlLiteral.new("(#{query.to_sql})")

        Gitlab::Database::AsWithMaterialized.new(table, sql, materialized: @materialized)
      end

      # Returns an "AS" statement that aliases the CTE name as the given table
      # name. This allows one to trick ActiveRecord into thinking it's selecting
      # from an actual table, when in reality it's selecting from a CTE.
      #
      # alias_table - The Arel table to use as the alias.
      def alias_to(alias_table)
        Arel::Nodes::As.new(table, alias_table)
      end

      # Applies the CTE to the given relation, returning a new one that will
      # query from it.
      def apply_to(relation)
        relation.except(:where)
          .with(to_arel)
          .from(alias_to(relation.model.arel_table))
      end
    end
  end
end
