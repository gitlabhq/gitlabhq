# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      module InOperatorOptimization
        class ColumnData
          attr_reader :original_column_name, :as, :arel_table

          def initialize(original_column_name, as, arel_table)
            @original_column_name = original_column_name.to_s
            @as = as.to_s
            @arel_table = arel_table
          end

          def projection
            arel_column.as(as)
          end

          def arel_column
            arel_table[original_column_name]
          end

          def arel_column_as
            arel_table[as]
          end

          def array_aggregated_column_name
            "#{arel_table.name}_#{original_column_name}_array"
          end

          def array_aggregated_column
            Arel::Nodes::NamedFunction.new('ARRAY_AGG', [arel_column]).as(array_aggregated_column_name)
          end
        end
      end
    end
  end
end
