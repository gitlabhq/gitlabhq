# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module Aggregated
        # Arguments:
        #   stage - an instance of CycleAnalytics::ProjectStage or CycleAnalytics::GroupStage
        #   params:
        #     current_user: an instance of User
        #     from: DateTime
        #     to: DateTime
        class DataCollector
          include Gitlab::Utils::StrongMemoize

          MAX_COUNT = 10001

          delegate :serialized_records, to: :records_fetcher

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
              RecordsFetcher.new(stage: stage, query: query, params: params)
            end
          end

          private

          attr_reader :stage, :params

          def query
            BaseQueryBuilder.new(stage: stage, params: params).build
          end

          def limit_count
            query.limit(MAX_COUNT).count
          end
        end
      end
    end
  end
end
