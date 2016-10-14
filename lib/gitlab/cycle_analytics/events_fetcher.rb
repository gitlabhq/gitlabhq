module Gitlab
  module CycleAnalytics
    class EventsFetcher
      include MetricsFetcher

      def initialize(project:, from:)
        @project = project
        @from = from
      end

      def fetch_issues
        cte_table = Arel::Table.new("cte_table_for_issue")

        # Build a `SELECT` query. We find the first of the `end_time_attrs` that isn't `NULL` (call this end_time).
        # Next, we find the first of the start_time_attrs that isn't `NULL` (call this start_time).
        # We compute the (end_time - start_time) interval, and give it an alias based on the current
        # cycle analytics stage.

        base_query = base_query_for(:issue)

        diff_fn = subtract_datetimes_diff(base_query, issue_table[:created_at], metric_attributes)

        query = base_query.project(diff_fn.as('issue_diff'))

        ActiveRecord::Base.connection.execute(query.to_sql)
      end

      def metric_attributes
        [issue_metrics_table[:first_associated_with_milestone_at],
         issue_metrics_table[:first_added_to_board_at]]
      end
    end
  end
end
