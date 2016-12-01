module Gitlab
  module CycleAnalytics
    class CodeStage < BaseStage
      def description
        "Time until first merge request"
      end

      def median
        @fetcher.median(:code,
                        Issue::Metrics.arel_table[:first_mentioned_in_commit_at],
                        MergeRequest.arel_table[:created_at])
      end
    end
  end
end
