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
              order_by_columns.map do |column|
                column_name = column.original_column_name.to_s
                type = model.columns_hash[column_name].sql_type
                "NULL::#{type} AS #{column_name}"
              end
            end

            def columns
              order_by_columns.array_lookup_expressions_by_position(QueryBuilder::RECURSIVE_CTE_NAME)
            end

            def final_projections
              order_by_columns.map(&:original_column_name)
            end

            private

            attr_reader :model, :order_by_columns
          end
        end
      end
    end
  end
end
