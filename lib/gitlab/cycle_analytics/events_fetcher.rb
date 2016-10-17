module Gitlab
  module CycleAnalytics
    class EventsFetcher
      include MetricsFetcher

      def initialize(project:, from:)
        @project = project
        @from = from
      end

      def fetch_issues
        base_query = base_query_for(:issue)
        diff_fn = subtract_datetimes_diff(base_query, issue_table[:created_at], metric_attributes)

        query = base_query.join(user_table).on(issue_table[:author_id].eq(user_table[:id])).
          project(diff_fn.as('issue_diff'), *issue_projections).
          order(issue_table[:created_at].desc)

        ActiveRecord::Base.connection.execute(query.to_sql).first
      end

      def metric_attributes
        [issue_metrics_table[:first_associated_with_milestone_at],
         issue_metrics_table[:first_added_to_board_at]]
      end

      def issue_projections
        [issue_table[:title], issue_table[:iid], issue_table[:created_at], User.arel_table[:name]]
      end

      def user_table
        User.arel_table
      end
    end
  end
end
