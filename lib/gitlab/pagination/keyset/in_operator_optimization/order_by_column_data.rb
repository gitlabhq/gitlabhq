# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      module InOperatorOptimization
        class OrderByColumnData < ColumnData
          extend ::Gitlab::Utils::Override

          attr_reader :column

          # column - a ColumnOrderDefinition object
          # as - custom alias for the column
          # arel_table - relation where the column is located
          def initialize(column, as, arel_table)
            super(column.attribute_name.to_s, as, arel_table)
            @column = column
          end

          override :arel_column
          def arel_column
            column.column_expression
          end

          override :column_expression
          def column_expression
            arel_table[original_column_name]
          end

          def column_for_projection
            column.column_expression.as(original_column_name)
          end
        end
      end
    end
  end
end
