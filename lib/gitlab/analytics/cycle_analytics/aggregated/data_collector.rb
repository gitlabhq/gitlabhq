# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module Aggregated
        # Arguments:
        #   stage - an instance of CycleAnalytics::Stage
        #   params:
        #     current_user: an instance of User
        #     from: DateTime
        #     to: DateTime
        class DataCollector
          include Gitlab::Utils::StrongMemoize

          MAX_COUNT = 10001

          delegate :serialized_records, :records_for_graphql, to: :records_fetcher

          def initialize(stage:, params: {})
            @stage = stage
            @params = params
          end

          def median
            strong_memoize(:median) { Median.new(stage: stage, query: query, params: params) }
          end

          def count
            strong_memoize(:count) { limit_count }
          end

          def records_fetcher
            strong_memoize(:records_fetcher) do
              RecordsFetcher.new(stage: stage, query: query_builder.build_sorted_query, params: params)
            end
          end

          private

          attr_reader :stage, :params

          def query
            query_builder.build
          end

          def query_builder
            @query_builder = BaseQueryBuilder.new(stage: stage, params: params)
          end

          def limit_count
            query.limit(MAX_COUNT).count
          end
        end
      end
    end
  end
end

Gitlab::Analytics::CycleAnalytics::Aggregated::DataCollector.prepend_mod_with('Gitlab::Analytics::CycleAnalytics::Aggregated::DataCollector')
