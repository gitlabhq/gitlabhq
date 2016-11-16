module Gitlab
  module CycleAnalytics
    class PlanConfig < BaseConfig
      @start_time_attrs = issue_metrics_table[:first_associated_with_milestone_at]

      @end_time_attrs = [issue_metrics_table[:first_added_to_board_at],
                         issue_metrics_table[:first_mentioned_in_commit_at]]

      @projections = [mr_diff_table[:st_commits].as('commits'),
                      issue_metrics_table[:first_mentioned_in_commit_at]]

      def self.query(base_query)
        base_query.join(mr_diff_table).on(mr_diff_table[:merge_request_id].eq(mr_table[:id]))
      end
    end
  end
end
