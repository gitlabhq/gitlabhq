module Gitlab
  module CycleAnalytics
    module BaseQuery
      include MetricsTables
      include Gitlab::Database::Median
      include Gitlab::Database::DateTime

      private

      def base_query
        @base_query ||= stage_query
      end

      def stage_query
        query = mr_closing_issues_table.join(issue_table).on(issue_table[:id].eq(mr_closing_issues_table[:issue_id]))
          .join(issue_metrics_table).on(issue_table[:id].eq(issue_metrics_table[:issue_id]))
          .where(issue_table[:project_id].eq(@project.id)) # rubocop:disable Gitlab/ModuleWithInstanceVariables
          .where(issue_table[:created_at].gteq(@options[:from])) # rubocop:disable Gitlab/ModuleWithInstanceVariables

        # Load merge_requests
        query = query.join(mr_table, Arel::Nodes::OuterJoin)
          .on(mr_table[:id].eq(mr_closing_issues_table[:merge_request_id]))
          .join(mr_metrics_table)
          .on(mr_table[:id].eq(mr_metrics_table[:merge_request_id]))

        query
      end
    end
  end
end
