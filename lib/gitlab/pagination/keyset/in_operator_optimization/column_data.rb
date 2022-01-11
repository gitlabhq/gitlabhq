# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      module InOperatorOptimization
        # This class is used for wrapping an Arel column with
        # convenient helper methods in order to make the query
        # building for the InOperatorOptimization a bit cleaner.
        class ColumnData
          attr_reader :original_column_name, :as, :arel_table

          # column - name of the DB column
          # as - custom alias for the column
          # arel_table - relation where the column is located
          def initialize(column, as, arel_table)
            @original_column_name = column
            @as = as.to_s
            @arel_table = arel_table
          end

          # Generates: `issues.name AS my_alias`
          def projection
            arel_column.as(as)
          end

          # Generates: issues.name`
          def arel_column
            arel_table[original_column_name]
          end

          # overridden in OrderByColumnData class
          alias_method :column_expression, :arel_column

          # Generates: `issues.my_alias`
          def arel_column_as
            arel_table[as]
          end

          def array_aggregated_column_name
            "#{arel_table.name}_#{original_column_name}_array"
          end

          # Generates: SELECT ARRAY_AGG(...) AS issues_name_array
          def array_aggregated_column
            Arel::Nodes::NamedFunction.new('ARRAY_AGG', [column_expression]).as(array_aggregated_column_name)
          end
        end
      end
    end
  end
end
