# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        class Max < MetricDefinition
          def initialize(name, type = :float, expression = nil, **kwargs)
            super
          end

          def identifier
            dotted_name? ? name : :"max_#{name}"
          end

          def to_outer_arel(context)
            inner_column = Arel::Table.new(context[:inner_query_name])[context.fetch(:local_alias, name)]

            if secondary_expression
              inner_condition_column = Arel::Table.new(context[:inner_query_name])[context.fetch(:local_secondary_alias,
                name)]
              Arel::Nodes::NamedFunction.new('maxIf', [inner_column, inner_condition_column.eq(1)])
            else
              Arel::Nodes::NamedFunction.new('max', [inner_column])
            end
          end
        end
      end
    end
  end
end
