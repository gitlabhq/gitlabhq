# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        class AggregationResult < Gitlab::Database::Aggregation::AggregationResult
          private

          def load_data
            ::ClickHouse::Client.select(query, :main)
          end

          def load_count
            count_expr = Arel::Nodes::NamedFunction.new('COUNT', []).as('rows_count')
            count_query = ::ClickHouse::Client::QueryBuilder
              .new(query, 'count_subquery')
              .select(count_expr)
            result = ::ClickHouse::Client.select(count_query, :main)
            result.first['rows_count'].to_i
          end
        end
      end
    end
  end
end
