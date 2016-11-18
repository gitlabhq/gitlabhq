module Gitlab
  module CycleAnalytics
    class TestStage < BaseStage
      def median
        @fetcher.calculate_metric(:test,
                                  MergeRequest::Metrics.arel_table[:latest_build_started_at],
                                  MergeRequest::Metrics.arel_table[:latest_build_finished_at])
      end
    end
  end
end
