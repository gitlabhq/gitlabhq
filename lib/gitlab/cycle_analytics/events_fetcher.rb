module Gitlab
  module CycleAnalytics
    class EventsFetcher
      include MetricsFetcher

      def initialize(project:, options:)
        @query = EventsQuery.new(project: project, options: options)
      end

      def fetch(stage:)
        custom_query = "#{stage}_custom_query".to_sym

        @query.execute(stage) do |base_query|
          public_send(custom_query, base_query) if self.respond_to?(custom_query)
        end
      end

      def issue_custom_query(base_query)
        base_query.join(user_table).on(issue_table[:author_id].eq(user_table[:id]))
      end

      def plan_custom_query(base_query)
        base_query.join(mr_diff_table).on(mr_diff_table[:merge_request_id].eq(mr_table[:id]))
      end

      def review_custom_query(base_query)
        base_query.join(user_table).on(mr_table[:author_id].eq(user_table[:id]))
      end

      def test_custom_query(base_query)
        base_query.join(build_table).on(mr_metrics_table[:ci_commit_id].eq(build_table[:commit_id]))
      end

      alias_method :code_custom_query, :issue_custom_query
      alias_method :production_custom_query, :issue_custom_query
      alias_method :staging_custom_query, :test_custom_query
    end
  end
end
