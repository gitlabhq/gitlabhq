# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        class Count < Column
          attr_reader :distinct

          def initialize(name = 'total', type = :integer, expression = nil, distinct: false, **kwargs)
            @distinct = distinct
            super
          end

          def identifier
            :"#{name}_count"
          end

          def to_inner_arel(...)
            expression&.call
          end

          def to_outer_arel(context)
            return regular_count(context) unless secondary_expression

            inner_condition_column = Arel::Table.new(context[:inner_query_name])[context.fetch(:local_secondary_alias,
              name)]
            Arel::Nodes::NamedFunction.new('countIf', [inner_condition_column.eq(1)])
          end

          def regular_count(context)
            inner_column = Arel::Table.new(context[:inner_query_name])[context[:local_alias]] if context[:local_alias]
            Arel::Nodes::Count.new([inner_column || Arel.star], distinct)
          end
        end
      end
    end
  end
end
