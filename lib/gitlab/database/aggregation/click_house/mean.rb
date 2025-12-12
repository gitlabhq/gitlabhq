# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        class Mean < Column
          def initialize(name, type = :float, expression = nil, **kwargs)
            super
          end

          def identifier
            :"mean_#{name}"
          end

          def to_outer_arel(context)
            return super.average unless secondary_expression

            inner_column = Arel::Table.new(context[:inner_query_name])[context.fetch(:local_alias, name)]
            inner_condition_column = Arel::Table.new(context[:inner_query_name])[context.fetch(:local_secondary_alias,
              name)]
            Arel::Nodes::NamedFunction.new('avgIf', [inner_column, inner_condition_column.eq(1)])
          end
        end
      end
    end
  end
end
