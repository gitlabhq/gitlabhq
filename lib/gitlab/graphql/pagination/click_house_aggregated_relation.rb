# frozen_string_literal: true

module Gitlab
  module Graphql
    module Pagination
      # A wrapper class for ClickHouse aggregated query results that need cursor pagination
      # This is used instead of ClickHouseConnection for GROUP BY queries with aggregations
      class ClickHouseAggregatedRelation < SimpleDelegator
      end
    end
  end
end
