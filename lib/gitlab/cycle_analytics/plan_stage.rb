module Gitlab
  module CycleAnalytics
    class PlanStage < BaseStage
      def initialize(*args)
        @start_time_attrs = [issue_metrics_table[:first_associated_with_milestone_at],
                             issue_metrics_table[:first_added_to_board_at]]
        @end_time_attrs = issue_metrics_table[:first_mentioned_in_commit_at]

        super(*args)
      end

      def name
        :plan
      end

      def description
        "Time before an issue starts implementation"
      end
    end
  end
end
