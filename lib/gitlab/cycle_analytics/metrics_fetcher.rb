module Gitlab
  module CycleAnalytics
    class MetricsFetcher
      include Gitlab::Database::Median
      include Gitlab::Database::DateTime
      include MetricsTables

      attr_reader :project

      DEPLOYMENT_METRIC_STAGES = %i[production staging]

      def initialize(project:, from:, branch:, stage:)
        @project = project
        @from = from
        @branch = branch
        @stage = stage
      end

      def median
        cte_table = Arel::Table.new("cte_table_for_#{@stage.stage}")

        # Build a `SELECT` query. We find the first of the `end_time_attrs` that isn't `NULL` (call this end_time).
        # Next, we find the first of the start_time_attrs that isn't `NULL` (call this start_time).
        # We compute the (end_time - start_time) interval, and give it an alias based on the current
        # cycle analytics stage.
        interval_query = Arel::Nodes::As.new(
          cte_table,
          subtract_datetimes(base_query_for(name), @stage.start_time_attrs, @stage.end_time_attrs, @stage.stage.to_s))

        median_datetime(cte_table, interval_query, name)
      end

      def events
        ActiveRecord::Base.connection.exec_query(events_query.to_sql)
      end

      private

      def events_query
        base_query = base_query_for(@stage.stage)

        diff_fn = subtract_datetimes_diff(base_query, @stage.start_time_attrs, @stage.end_time_attrs)

        @stage.event.custom_query(base_query)

        base_query.project(extract_diff_epoch(diff_fn).as('total_time'), *@stage.event.projections).order(order.desc)
      end

      def order
        @stage.event.order || default_order
      end

      def default_order
        @stage.start_time_attrs.is_a?(Array) ? @stage.start_time_attrs.first : @stage.start_time_attrs
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

        query = query.where(build_table[:ref].eq(@branch)) if name == :test && @branch

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
    end
  end
end
