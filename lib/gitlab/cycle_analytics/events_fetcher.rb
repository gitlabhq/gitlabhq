module Gitlab
  module CycleAnalytics
    class EventsFetcher
      include MetricsFetcher

      EVENTS_CONFIG = {
        issue: {
          start_time_attrs: issue_table[:created_at],
          end_time_attrs: [issue_metrics_table[:first_associated_with_milestone_at],
                           issue_metrics_table[:first_added_to_board_at]],
          projections: [issue_table[:title], issue_table[:iid], issue_table[:created_at], user_table[:name]]
        },
        plan: {
          start_time_attrs: issue_metrics_table[:first_associated_with_milestone_at],
          end_time_attrs: [issue_metrics_table[:first_added_to_board_at],
                           issue_metrics_table[:first_mentioned_in_commit_at]],
          projections: [mr_diff_table[:st_commits].as('commits'), issue_metrics_table[:first_mentioned_in_commit_at]]
        },
        code: {
          start_time_attrs: issue_metrics_table[:first_mentioned_in_commit_at],
          end_time_attrs: mr_table[:created_at],
          projections: [mr_table[:title], mr_table[:iid], mr_table[:created_at], user_table[:name]],
          order: mr_table[:created_at]
        },
        test: {
          start_time_attrs: mr_metrics_table[:latest_build_started_at],
          end_time_attrs: mr_metrics_table[:latest_build_finished_at],
          projections: mr_metrics_table[:ci_commit_id],
          order: mr_table[:created_at]
        },
        review: {
          start_time_attrs: mr_table[:created_at],
          end_time_attrs: mr_metrics_table[:merged_at],
          projections: [mr_table[:title], mr_table[:iid], mr_table[:created_at], user_table[:name]]
        },
        staging: {
          start_time_attrs: mr_metrics_table[:merged_at],
          end_time_attrs: mr_metrics_table[:first_deployed_to_production_at],
          projections: mr_metrics_table[:ci_commit_id]
        },
        production: {
          start_time_attrs: issue_table[:created_at],
          end_time_attrs: mr_metrics_table[:first_deployed_to_production_at],
          projections: [issue_table[:title], issue_table[:iid], issue_table[:created_at], user_table[:name]]
        },
      }.freeze

      def initialize(project:, from:)
        @query = EventsQuery.new(project: project, from: from)
      end

      def fetch(stage:)
        custom_query = "#{stage}_custom_query".to_sym

        @query.execute(stage, EVENTS_CONFIG[stage]) do |base_query|
          public_send(custom_query, base_query) if self.respond_to?(custom_query)
        end
      end

      def issue_custom_query(base_query)
        base_query.join(user_table).on(issue_table[:author_id].eq(user_table[:id]))
      end

      alias_method :code_custom_query, :issue_custom_query
      alias_method :production_custom_query, :issue_custom_query

      def plan_custom_query(base_query)
        base_query.join(mr_diff_table).on(mr_diff_table[:merge_request_id].eq(mr_table[:id]))
      end

      def review_custom_query(base_query)
        base_query.join(user_table).on(mr_table[:author_id].eq(user_table[:id]))
      end
    end
  end
end
