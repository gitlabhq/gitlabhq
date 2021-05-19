# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      # Arguments:
      #   stage - an instance of CycleAnalytics::ProjectStage or CycleAnalytics::GroupStage
      #   params:
      #     current_user: an instance of User
      #     from: DateTime
      #     to: DateTime
      class DataCollector
        include Gitlab::Utils::StrongMemoize

        MAX_COUNT = 1001

        delegate :serialized_records, to: :records_fetcher

        def initialize(stage:, params: {})
          @stage = stage
          @params = params
        end

        def records_fetcher
          strong_memoize(:records_fetcher) do
            RecordsFetcher.new(stage: stage, query: query, params: params)
          end
        end

        def median
          strong_memoize(:median) do
            Median.new(stage: stage, query: query, params: params)
          end
        end

        def average
          strong_memoize(:average) do
            Average.new(stage: stage, query: query, params: params)
          end
        end

        def count
          strong_memoize(:count) do
            limit_count
          end
        end

        private

        attr_reader :stage, :params

        def query
          BaseQueryBuilder.new(stage: stage, params: params).build
        end

        # Limiting the maximum number of records so the COUNT(*) query stays efficient for large groups.
        # COUNT = 1001, show 1000+ on the UI
        # COUNT < 1001, show the actual number on the UI
        def limit_count
          query.limit(MAX_COUNT).count
        end
      end
    end
  end
end

Gitlab::Analytics::CycleAnalytics::DataCollector.prepend_mod_with('Gitlab::Analytics::CycleAnalytics::DataCollector')
