# frozen_string_literal: true

module LooseIndexScan
  extend ActiveSupport::Concern

  class_methods do
    # Builds a recursive query to read distinct values from a column.
    #
    # Example 1: collect all distinct author ids for the `issues` table
    #
    # Bad: The DB reads all issues, sorts and dedups them in memory
    #
    # > Issue.select(:author_id).distinct.map(&:author_id)
    #
    # Good: Use loose index scan (skip index scan)
    #
    # > Issue.loose_index_scan(column: :author_id).map(&:author_id)
    #
    # Example 2: List of users for the DONE todos selector. Select all users who created a todo.
    #
    # Bad: Loads all DONE todos for the given user and extracts the author_ids
    #
    # > User.where(id: Todo.where(user_id: 4156052).done.select(:author_id))
    #
    # Good: Loads distinct author_ids from todos and then loads users
    #
    # > distinct_authors = Todo.where(user_id: 4156052).done.loose_index_scan(column: :author_id).select(:author_id)
    # > User.where(id: distinct_authors)
    def loose_index_scan(column:, order: :asc)
      arel_table = self.arel_table

      # Handle different column types
      arel_column, column_alias, column_for_select = extract_column_and_alias_and_select(column, arel_table)

      cte = Gitlab::SQL::RecursiveCTE.new(:loose_index_scan_cte, union_args: { remove_order: false })

      cte_query = except(:select)
        .select(column_for_select)
        .order(column_alias => order)
        .limit(1)

      inner_query = except(:select)

      cte_query, inner_query = yield([cte_query, inner_query]) if block_given?
      cte << cte_query

      inner_query = if order == :asc
                      inner_query.where(arel_column.gt(cte.table[column_alias]))
                    else
                      inner_query.where(arel_column.lt(cte.table[column_alias]))
                    end

      inner_query = inner_query
        .select(column_for_select)
        .order(column_alias => order)
        .limit(1)

      cte << cte.table
        .project(Arel::Nodes::Grouping.new(Arel.sql(inner_query.to_sql)).as(column_alias))

      unscoped do
        select(column_alias)
          .with
          .recursive(cte.to_arel)
          .from(cte.alias_to(arel_table))
          .where.not(column_alias => nil) # filtering out the last NULL value
      end
    end

    private

    def extract_column_and_alias_and_select(column, arel_table)
      case column
      when Arel::Nodes::As
        [column.left, column.right, column]
      when Arel::Attributes::Attribute
        [column, column.name, column.name]
      else
        [arel_table[column.to_s], column.to_s, column.to_s]
      end
    end
  end
end
