# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      module InOperatorOptimization
        module Strategies
          class OrderValuesLoaderStrategy
            def initialize(model, order_by_columns)
              @model = model
              @order_by_columns = order_by_columns
            end

            def initializer_columns
              order_by_columns.map { |column_data| null_with_type_cast(column_data) }
            end

            def columns
              order_by_columns.array_lookup_expressions_by_position(QueryBuilder::RECURSIVE_CTE_NAME)
            end

            def final_projections
              order_by_columns.map(&:original_column_name)
            end

            private

            attr_reader :model, :order_by_columns

            def null_with_type_cast(column_data)
              column_name = column_data.original_column_name.to_s
              active_record_column = model.columns_hash[column_name]

              type = active_record_column ? active_record_column.sql_type : column_data.column.sql_type

              "NULL::#{type} AS #{column_name}"
            end
          end
        end
      end
    end
  end
end
