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
            Median.new(stage: stage, query: query)
          end
        end

        private

        attr_reader :stage, :params

        def query
          BaseQueryBuilder.new(stage: stage, params: params).build
        end
      end
    end
  end
end

Gitlab::Analytics::CycleAnalytics::DataCollector.prepend_if_ee('EE::Gitlab::Analytics::CycleAnalytics::DataCollector')
