# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        class Rate < Column
          # Uses regular expression as numerator condition and "if" expression as denominator condition
          def initialize(name, type = :float, numerator_if:, denominator_if: nil)
            super(name, type, numerator_if, if: denominator_if)
          end

          def identifier
            :"#{name}_rate"
          end

          def to_outer_arel(context)
            inner_column = Arel::Table.new(context[:inner_query_name])[context.fetch(:local_alias, name)]

            if secondary_expression
              inner_condition_column = Arel::Table.new(context[:inner_query_name])[context.fetch(:local_secondary_alias,
                name)]
              denominator = Arel::Nodes::NamedFunction.new('countIf', [inner_condition_column.eq(1)])
            else
              denominator = Arel::Nodes::Count.new([Arel.star])
            end

            Arel::Nodes::NamedFunction.new('countIf', [inner_column.eq(1)]) / denominator
          end
        end
      end
    end
  end
end
