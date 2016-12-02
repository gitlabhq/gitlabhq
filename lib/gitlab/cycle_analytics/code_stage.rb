module Gitlab
  module CycleAnalytics
    class CodeStage < BaseStage
      def initialize(*args)
        @start_time_attrs = issue_metrics_table[:first_mentioned_in_commit_at]
        @end_time_attrs = mr_table[:created_at]

        super(*args)
      end

      def stage
        :code
      end

      def description
        "Time until first merge request"
      end
    end
  end
end
