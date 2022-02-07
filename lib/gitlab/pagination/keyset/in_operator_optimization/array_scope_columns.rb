# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      module InOperatorOptimization
        class ArrayScopeColumns
          ARRAY_SCOPE_CTE_NAME = 'array_cte'

          def initialize(columns)
            validate_columns!(columns)

            array_scope_table = Arel::Table.new(ARRAY_SCOPE_CTE_NAME)
            @columns = columns.map do |column|
              column = column.right if column.is_a?(Arel::Nodes::As)
              ColumnData.new(column, "array_scope_#{column}", array_scope_table)
            end
          end

          def array_scope_cte_name
            ARRAY_SCOPE_CTE_NAME
          end

          def array_aggregated_columns
            columns.map(&:array_aggregated_column)
          end

          def array_aggregated_column_names
            columns.map(&:array_aggregated_column_name)
          end

          def arel_columns
            columns.map(&:arel_column)
          end

          def array_lookup_expressions_by_position(table_name)
            columns.map do |column|
              Arel.sql("#{table_name}.#{column.array_aggregated_column_name}[position]")
            end
          end

          private

          attr_reader :columns

          def validate_columns!(columns)
            if columns.blank?
              msg = <<~MSG
              No array columns were given.
              Make sure you explicitly select the columns in the array_scope parameter.
              Example: Project.select(:id)
              MSG
              raise StandardError, msg
            end
          end
        end
      end
    end
  end
end
