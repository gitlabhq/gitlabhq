# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      # Arguments:
      #   stage - an instance of CycleAnalytics::Stage
      #   params:
      #     current_user: an instance of User
      #     from: DateTime
      #     to: DateTime
      class DataCollector
        include Gitlab::Utils::StrongMemoize

        MAX_COUNT = 1001

        delegate :serialized_records, :records_for_graphql, to: :records_fetcher

        def initialize(stage:, params: {})
          @stage = stage
          @params = params
        end

        def records_fetcher
          strong_memoize(:records_fetcher) do
            if use_aggregated_data_collector?
              aggregated_data_collector.records_fetcher
            else
              RecordsFetcher.new(stage: stage, query: query, params: params)
            end
          end
        end

        def median
          strong_memoize(:median) do
            if use_aggregated_data_collector?
              aggregated_data_collector.median
            else
              Median.new(stage: stage, query: query, params: params)
            end
          end
        end

        def average
          strong_memoize(:average) do
            Average.new(stage: stage, query: query, params: params)
          end
        end

        def count
          strong_memoize(:count) do
            if use_aggregated_data_collector?
              aggregated_data_collector.count
            else
              limit_count
            end
          end
        end

        attr_reader :stage, :params

        private

        def query
          query_builder.build
        end

        def query_builder
          @query_builder ||= BaseQueryBuilder.new(stage: stage, params: params)
        end

        # Limiting the maximum number of records so the COUNT(*) query stays efficient for large groups.
        # COUNT = 1001, show 1000+ on the UI
        # COUNT < 1001, show the actual number on the UI
        def limit_count
          query.limit(MAX_COUNT).count
        end

        def aggregated_data_collector
          @aggregated_data_collector ||= Aggregated::DataCollector.new(stage: stage, params: params)
        end

        def use_aggregated_data_collector?
          params.fetch(:use_aggregated_data_collector, false)
        end
      end
    end
  end
end

Gitlab::Analytics::CycleAnalytics::DataCollector.prepend_mod_with('Gitlab::Analytics::CycleAnalytics::DataCollector')
