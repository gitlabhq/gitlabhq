module Gitlab
  module CycleAnalytics
    module MetricsFetcher
      include Gitlab::Database::Median
      include Gitlab::Database::DateTime

      DEPLOYMENT_METRIC_STAGES = %i[production staging]

      private

      def calculate_metric(name, start_time_attrs, end_time_attrs)
        cte_table = Arel::Table.new("cte_table_for_#{name}")

        # Build a `SELECT` query. We find the first of the `end_time_attrs` that isn't `NULL` (call this end_time).
        # Next, we find the first of the start_time_attrs that isn't `NULL` (call this start_time).
        # We compute the (end_time - start_time) interval, and give it an alias based on the current
        # cycle analytics stage.
        interval_query = Arel::Nodes::As.new(
          cte_table,
          subtract_datetimes(base_query_for(name), start_time_attrs, end_time_attrs, name.to_s))

        median_datetime(cte_table, interval_query, name)
      end

      # Join table with a row for every <issue,merge_request> pair (where the merge request
      # closes the given issue) with issue and merge request metrics included. The metrics
      # are loaded with an inner join, so issues / merge requests without metrics are
      # automatically excluded.
      def base_query_for(name)
        # Load issues
        query = mr_closing_issues_table.join(issue_table).on(issue_table[:id].eq(mr_closing_issues_table[:issue_id])).
          join(issue_metrics_table).on(issue_table[:id].eq(issue_metrics_table[:issue_id])).
          where(issue_table[:project_id].eq(@project.id)).
          where(issue_table[:deleted_at].eq(nil)).
          where(issue_table[:created_at].gteq(@from))

        # Load merge_requests
        query = query.join(mr_table, Arel::Nodes::OuterJoin).
          on(mr_table[:id].eq(mr_closing_issues_table[:merge_request_id])).
          join(mr_metrics_table).
          on(mr_table[:id].eq(mr_metrics_table[:merge_request_id]))

        if DEPLOYMENT_METRIC_STAGES.include?(name)
          # Limit to merge requests that have been deployed to production after `@from`
          query.where(mr_metrics_table[:first_deployed_to_production_at].gteq(@from))
        end

        query
      end

      def mr_metrics_table
        MergeRequest::Metrics.arel_table
      end

      def mr_table
        MergeRequest.arel_table
      end

      def mr_diff_table
        MergeRequestDiff.arel_table
      end

      def mr_closing_issues_table
        MergeRequestsClosingIssues.arel_table
      end

      def issue_table
        Issue.arel_table
      end

      def issue_metrics_table
        Issue::Metrics.arel_table
      end
    end
  end
end
