module Gitlab
  module CycleAnalytics
    class CodeStage < BaseStage
      def initialize(*args)
        super(*args)

        @description = "Time until first merge request"
      end

      def median
        @fetcher.calculate_metric(:code,
                                  Issue::Metrics.arel_table[:first_mentioned_in_commit_at],
                                  MergeRequest.arel_table[:created_at])
      end
    end
  end
end
