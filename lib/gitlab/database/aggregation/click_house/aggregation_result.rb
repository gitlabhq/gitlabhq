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
        end
      end
    end
  end
end
