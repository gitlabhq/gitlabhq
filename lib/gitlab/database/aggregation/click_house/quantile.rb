# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        class Quantile < MetricDefinition
          DEFAULT_QUANTILE = 0.5

          def initialize(name, type = :float, expression = nil, **kwargs)
            super
          end

          def identifier
            dotted_name? ? name : :"#{name}_quantile"
          end

          def to_outer_arel(context)
            quantile = instance_parameter(:quantile, context[name]) || DEFAULT_QUANTILE

            inner_column = Arel::Table.new(context[:inner_query_name])[context.fetch(:local_alias, name)]

            # `quantile` samples above 8192 values and can return different numbers for the same query.
            Arel.sql("quantileExactInclusive(?)(?)", context[:scope].quote(quantile), inner_column)
          end
        end
      end
    end
  end
end
