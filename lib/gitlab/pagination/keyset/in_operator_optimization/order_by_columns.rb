# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      module InOperatorOptimization
        class OrderByColumns
          include Enumerable

          # This class exposes collection methods for the order by columns
          #
          # Example: by modeling the `issues.created_at ASC, issues.id ASC` ORDER BY
          # SQL clause, this class will receive two ColumnOrderDefinition objects
          def initialize(columns, arel_table)
            @columns = columns.map do |column|
              OrderByColumnData.new(column, "order_by_columns_#{column.attribute_name}", arel_table)
            end
          end

          def arel_columns
            columns.map(&:column_for_projection)
          end

          def array_aggregated_columns
            columns.map(&:array_aggregated_column)
          end

          def array_aggregated_column_names
            columns.map(&:array_aggregated_column_name)
          end

          def original_column_names
            columns.map(&:original_column_name)
          end

          def original_column_names_as_arel_string
            columns.map { |c| Arel.sql(c.original_column_name) }
          end

          def original_column_names_as_tmp_tamble
            temp_table = Arel::Table.new('record')
            original_column_names.map { |c| temp_table[c] }
          end

          def cursor_values(table_name)
            columns.each_with_object({}) do |column, hash|
              hash[column.original_column_name] = Arel.sql("#{table_name}.#{column.array_aggregated_column_name}[position]")
            end
          end

          def array_lookup_expressions_by_position(table_name)
            columns.map do |column|
              Arel.sql("#{table_name}.#{column.array_aggregated_column_name}[position]")
            end
          end

          def replace_value_in_array_by_position_expressions
            columns.map do |column|
              name = "#{QueryBuilder::RECURSIVE_CTE_NAME}.#{column.array_aggregated_column_name}"
              new_value = "next_cursor_values.#{column.original_column_name}"
              "#{name}[:position_query.position-1]||#{new_value}||#{name}[position_query.position+1:]"
            end
          end

          def each(&block)
            columns.each(&block)
          end

          private

          attr_reader :columns
        end
      end
    end
  end
end
