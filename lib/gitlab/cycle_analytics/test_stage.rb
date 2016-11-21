module Gitlab
  module CycleAnalytics
    class TestStage < BaseStage
      def initialize(*args)
        super(*args)

        @description = "Total test time for all commits/merges"
      end

      def median
        @fetcher.calculate_metric(:test,
                                  MergeRequest::Metrics.arel_table[:latest_build_started_at],
                                  MergeRequest::Metrics.arel_table[:latest_build_finished_at])
      end
    end
  end
end
