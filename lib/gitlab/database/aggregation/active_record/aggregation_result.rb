# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ActiveRecord
        class AggregationResult < Gitlab::Database::Aggregation::AggregationResult
          private

          def load_data
            query.model.connection.select_all(query.limit(1000).to_sql)
          end
        end
      end
    end
  end
end
