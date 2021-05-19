# frozen_string_literal: true

module Gitlab
  module Database
    # This class builds efficient batched distinct query by using loose index scan.
    # Consider the following example:
    # > Issue.distinct(:project_id).where(project_id: (1...100)).count
    #
    # Note: there is an index on project_id
    #
    # This query will read each element in the index matching the project_id filter.
    # If for a project_id has 100_000 issues, all 100_000 elements will be read.
    #
    # A loose index scan will only read one entry from the index for each project_id to reduce the number of disk reads.
    #
    # Usage:
    #
    # Gitlab::Database::LooseIndexScanDisctinctCount.new(Issue, :project_id).count(from: 1, to: 100)
    #
    # The query will return the number of distinct projects_ids between 1 and 100
    #
    # Getting the Arel query:
    #
    # Gitlab::Database::LooseIndexScanDisctinctCount.new(Issue, :project_id).build_query(from: 1, to: 100)
    class LooseIndexScanDistinctCount
      COLUMN_ALIAS = 'distinct_count_column'

      ColumnConfigurationError = Class.new(StandardError)

      def initialize(scope, column)
        if scope.is_a?(ActiveRecord::Relation)
          @scope = scope
          @model = scope.model
        else
          @scope = scope.where({})
          @model = scope
        end

        @column = transform_column(column)
      end

      def count(from:, to:)
        build_query(from: from, to: to).count(COLUMN_ALIAS)
      end

      def build_query(from:, to:) # rubocop:disable Metrics/AbcSize
        cte = Gitlab::SQL::RecursiveCTE.new(:counter_cte, union_args: { remove_order: false })
        table = model.arel_table

        cte << @scope
          .dup
          .select(column.as(COLUMN_ALIAS))
          .where(column.gteq(from))
          .where(column.lt(to))
          .order(column)
          .limit(1)

        inner_query = @scope
          .dup
          .where(column.gt(cte.table[COLUMN_ALIAS]))
          .where(column.lt(to))
          .select(column.as(COLUMN_ALIAS))
          .order(column)
          .limit(1)

        cte << cte.table
          .project(Arel::Nodes::Grouping.new(Arel.sql(inner_query.to_sql)).as(COLUMN_ALIAS))
          .where(cte.table[COLUMN_ALIAS].lt(to))

        model
          .with
          .recursive(cte.to_arel)
          .from(cte.alias_to(table))
          .unscope(where: :source_type)
          .unscope(where: model.inheritance_column) # Remove STI query, not needed here
      end

      private

      attr_reader :column, :model

      # Transforms the column so it can be used in Arel expressions
      #
      # 'table.column' => 'table.column'
      # 'column' => 'table_name.column'
      # :column => 'table_name.column'
      # Arel::Attributes::Attribute => name of the column
      def transform_column(column)
        if column.is_a?(String) || column.is_a?(Symbol)
          column_as_string = column.to_s
          column_as_string = "#{model.table_name}.#{column_as_string}" unless column_as_string.include?('.')

          Arel.sql(column_as_string)
        elsif column.is_a?(Arel::Attributes::Attribute)
          column
        else
          raise ColumnConfigurationError, "Cannot transform the column: #{column.inspect}, please provide the column name as string"
        end
      end
    end
  end
end
