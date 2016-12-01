module Gitlab
  module CycleAnalytics
    class ReviewStage < BaseStage
      def description
        "Time between merge request creation and merge/close"
      end

      def median
        @fetcher.median(:review,
                        MergeRequest.arel_table[:created_at],
                        MergeRequest::Metrics.arel_table[:merged_at])
      end
    end
  end
end
