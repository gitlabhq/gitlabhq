# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ActiveRecord
        class AggregationResult < Gitlab::Database::Aggregation::AggregationResult
          private

          def load_data
            query.model.connection.select_all(query.to_sql)
          end

          def load_count
            query.model.connection.select_value("SELECT COUNT(*) FROM (#{query.to_sql}) ar_subquery").to_i
          end
        end
      end
    end
  end
end
