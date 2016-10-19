module Gitlab
  module CycleAnalytics
    class EventsFetcher
      include MetricsFetcher

      def initialize(project:, from:)
        @project = project
        @from = from
      end

      def fetch_issue_events
        base_query = base_query_for(:issue)
        diff_fn = subtract_datetimes_diff(base_query, issue_table[:created_at], issue_attributes)

        query = base_query.join(user_table).on(issue_table[:author_id].eq(user_table[:id])).
          project(extract_epoch(diff_fn).as('total_time'), *issue_projections).
          order(issue_table[:created_at].desc)

        ActiveRecord::Base.connection.execute(query.to_sql).to_a
      end

      def fetch_plan_events
        base_query = base_query_for(:plan)
        diff_fn = subtract_datetimes_diff(base_query, issue_table[:created_at], plan_attributes)

        query = base_query.join(merge_request_diff_table).on(merge_request_diff_table[:merge_request_id].eq(merge_request_table[:id])).
          project(merge_request_diff_table[:st_commits].as(:commits), extract_epoch(diff_fn).as('total_time')).
          order(issue_table[:created_at].desc)

        ActiveRecord::Base.connection.execute(query.to_sql).to_a
      end

      private

      def issue_attributes
        [issue_metrics_table[:first_associated_with_milestone_at],
         issue_metrics_table[:first_added_to_board_at]]
      end

      def plan_attributes
        issue_attributes + [issue_metrics_table[:first_mentioned_in_commit_at]]
      end

      def issue_projections
        [issue_table[:title], issue_table[:iid], issue_table[:created_at], User.arel_table[:name]]
      end

      def user_table
        User.arel_table
      end

      def extract_epoch(arel_attribute)
        Arel.sql(%Q{EXTRACT(EPOCH FROM (#{arel_attribute.to_sql}))})
      end
    end
  end
end
