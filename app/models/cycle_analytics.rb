class CycleAnalytics
  include Gitlab::Database::Median
  include Gitlab::Database::DateTime

  DEPLOYED_CHECK_METRICS = %i[production staging]

  def initialize(project, from:)
    @project = project
    @from = from
  end

  def summary
    @summary ||= Summary.new(@project, from: @from)
  end

  def issue
    calculate_metric(:issue,
                     Issue.arel_table[:created_at],
                     [Issue::Metrics.arel_table[:first_associated_with_milestone_at],
                      Issue::Metrics.arel_table[:first_added_to_board_at]])
  end

  def plan
    calculate_metric(:plan,
                     [Issue::Metrics.arel_table[:first_associated_with_milestone_at],
                      Issue::Metrics.arel_table[:first_added_to_board_at]],
                     Issue::Metrics.arel_table[:first_mentioned_in_commit_at])
  end

  def code
    calculate_metric(:code,
                     Issue::Metrics.arel_table[:first_mentioned_in_commit_at],
                     MergeRequest.arel_table[:created_at])
  end

  def test
    calculate_metric(:test,
                     MergeRequest::Metrics.arel_table[:latest_build_started_at],
                     MergeRequest::Metrics.arel_table[:latest_build_finished_at])
  end

  def review
    calculate_metric(:review,
                     MergeRequest.arel_table[:created_at],
                     MergeRequest::Metrics.arel_table[:merged_at])
  end

  def staging
    calculate_metric(:staging,
                     MergeRequest::Metrics.arel_table[:merged_at],
                     MergeRequest::Metrics.arel_table[:first_deployed_to_production_at])
  end

  def production
    calculate_metric(:production,
                     Issue.arel_table[:created_at],
                     MergeRequest::Metrics.arel_table[:first_deployed_to_production_at])
  end

  private

  def calculate_metric(name, start_time_attrs, end_time_attrs)
    cte_table = Arel::Table.new("cte_table_for_#{name}")

    # Build a `SELECT` query. We find the first of the `end_time_attrs` that isn't `NULL` (call this end_time).
    # Next, we find the first of the start_time_attrs that isn't `NULL` (call this start_time).
    # We compute the (end_time - start_time) interval, and give it an alias based on the current
    # cycle analytics stage.
    interval_query = Arel::Nodes::As.new(
      cte_table,
      subtract_datetimes(base_query_for(name), end_time_attrs, start_time_attrs, name.to_s))

    median_datetime(cte_table, interval_query, name)
  end

  # Join table with a row for every <issue,merge_request> pair (where the merge request
  # closes the given issue) with issue and merge request metrics included. The metrics
  # are loaded with an inner join, so issues / merge requests without metrics are
  # automatically excluded.
  def base_query_for(name)
    arel_table = MergeRequestsClosingIssues.arel_table

    # Load issues
    query = arel_table.join(Issue.arel_table).on(Issue.arel_table[:id].eq(arel_table[:issue_id])).
            join(Issue::Metrics.arel_table).on(Issue.arel_table[:id].eq(Issue::Metrics.arel_table[:issue_id])).
            where(Issue.arel_table[:project_id].eq(@project.id)).
            where(Issue.arel_table[:deleted_at].eq(nil)).
            where(Issue.arel_table[:created_at].gteq(@from))

    # Load merge_requests
    query = query.join(MergeRequest.arel_table, Arel::Nodes::OuterJoin).
            on(MergeRequest.arel_table[:id].eq(arel_table[:merge_request_id])).
            join(MergeRequest::Metrics.arel_table).
            on(MergeRequest.arel_table[:id].eq(MergeRequest::Metrics.arel_table[:merge_request_id]))

    if DEPLOYED_CHECK_METRICS.include?(name)
      # Limit to merge requests that have been deployed to production after `@from`
      query.where(MergeRequest::Metrics.arel_table[:first_deployed_to_production_at].gteq(@from))
    end

    query
  end
end
