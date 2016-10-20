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

        execute(query)
      end

      def fetch_plan_events
        base_query = base_query_for(:plan)
        diff_fn = subtract_datetimes_diff(base_query,
                                          issue_metrics_table[:first_associated_with_milestone_at],
                                          plan_attributes)

        query = base_query.join(mr_diff_table).on(mr_diff_table[:merge_request_id].eq(mr_table[:id])).
          project(extract_epoch(diff_fn).as('total_time'), *plan_projections).
          order(issue_metrics_table[:first_associated_with_milestone_at].desc)

        execute(query)
      end

      def fetch_code_events
        base_query = base_query_for(:code)
        diff_fn = subtract_datetimes_diff(base_query,
                                          issue_metrics_table[:first_mentioned_in_commit_at],
                                          issue_table[:created_at])

        query = base_query.join(user_table).on(issue_table[:author_id].eq(user_table[:id])).
          project(extract_epoch(diff_fn).as('total_time'), *code_projections).
          order(mr_table[:created_at].desc)

        execute(query)
      end

      private

      def issue_attributes
        [issue_metrics_table[:first_associated_with_milestone_at],
         issue_metrics_table[:first_added_to_board_at]]
      end

      def plan_attributes
        [issue_metrics_table[:first_added_to_board_at],
         issue_metrics_table[:first_mentioned_in_commit_at]]
      end

      def issue_projections
        [issue_table[:title], issue_table[:iid], issue_table[:created_at], User.arel_table[:name]]
      end

      def plan_projections
        [mr_diff_table[:st_commits].as('commits'), issue_metrics_table[:first_mentioned_in_commit_at]]
      end

      def code_projections
        [mr_table[:title], mr_table[:iid], mr_table[:created_at], User.arel_table[:name]]
      end

      def user_table
        User.arel_table
      end

      def extract_epoch(arel_attribute)
        Arel.sql(%Q{EXTRACT(EPOCH FROM (#{arel_attribute.to_sql}))})
      end

      def execute(query)
        ActiveRecord::Base.connection.execute(query.to_sql).to_a
      end
    end
  end
end
