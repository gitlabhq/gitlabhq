module Gitlab
  module CycleAnalytics
    class TestStage < BaseStage
      def description
        "Total test time for all commits/merges"
      end

      def median
        @fetcher.median(:test,
                        MergeRequest::Metrics.arel_table[:latest_build_started_at],
                        MergeRequest::Metrics.arel_table[:latest_build_finished_at])
      end
    end
  end
end
