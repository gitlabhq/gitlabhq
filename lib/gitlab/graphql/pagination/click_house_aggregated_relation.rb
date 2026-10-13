# frozen_string_literal: true

module Gitlab
  module Graphql
    module Pagination
      # A wrapper class for ClickHouse aggregated query results that need cursor pagination
      # This is used instead of ClickHouseConnection for GROUP BY queries with aggregations
      class ClickHouseAggregatedRelation < SimpleDelegator
        # Gitlab::ApplicationContext attributes applied when the deferred query runs in
        # ClickHouseAggregatedConnection#execute_query, after the resolver scope is gone.
        attr_reader :context_attributes

        def initialize(query_builder, context_attributes: {})
          super(query_builder)
          @context_attributes = context_attributes
        end
      end
    end
  end
end
