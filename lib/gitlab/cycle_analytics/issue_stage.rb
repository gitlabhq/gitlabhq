module Gitlab
  module CycleAnalytics
    class IssueStage < BaseStage
      def initialize(*args)
        @start_time_attrs = issue_table[:created_at]
        @end_time_attrs = [issue_metrics_table[:first_associated_with_milestone_at],
                           issue_metrics_table[:first_added_to_board_at]]

        super(*args)
      end

      def name
        :issue
      end

      def description
        "Time before an issue gets scheduled"
      end
    end
  end
end
