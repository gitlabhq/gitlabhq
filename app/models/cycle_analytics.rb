class CycleAnalytics
  include Gitlab::Database::Median
  include Gitlab::Database::DateTime

  def initialize(project, from:)
    @project = project
    @from = from
    @summary = Summary.new(project, from: from)
  end

  def summary
    @summary
  end

  def issue
    calculate_metric(:issue,
                     TableReferences.issues[:created_at],
                     [TableReferences.issue_metrics[:first_associated_with_milestone_at],
                      TableReferences.issue_metrics[:first_added_to_board_at]])
  end

  def plan
    calculate_metric(:plan,
                     [TableReferences.issue_metrics[:first_associated_with_milestone_at],
                      TableReferences.issue_metrics[:first_added_to_board_at]],
                     TableReferences.issue_metrics[:first_mentioned_in_commit_at])
  end

  def code
    calculate_metric(:code,
                     TableReferences.issue_metrics[:first_mentioned_in_commit_at],
                     TableReferences.merge_requests[:created_at])
  end

  def test
    calculate_metric(:test,
                     TableReferences.merge_request_metrics[:latest_build_started_at],
                     TableReferences.merge_request_metrics[:latest_build_finished_at])
  end

  def review
    calculate_metric(:review,
                     TableReferences.merge_requests[:created_at],
                     TableReferences.merge_request_metrics[:merged_at])
  end

  def staging
    calculate_metric(:staging,
                     TableReferences.merge_request_metrics[:merged_at],
                     TableReferences.merge_request_metrics[:first_deployed_to_production_at])
  end

  def production
    calculate_metric(:production,
                     TableReferences.issues[:created_at],
                     TableReferences.merge_request_metrics[:first_deployed_to_production_at])
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
      subtract_datetimes(base_query, end_time_attrs, start_time_attrs, name.to_s))

    median_queries = Array.wrap(median_datetime(cte_table, interval_query, name))
    results = median_queries.map { |query| run_query(query) }
    extract_median(results).presence
  end

  # Join table with a row for every <issue,merge_request> pair (where the merge request
  # closes the given issue) with issue and merge request metrics included. The metrics
  # are loaded with an inner join, so issues / merge requests without metrics are
  # automatically excluded.
  def base_query
    arel_table = TableReferences.merge_requests_closing_issues

    # Load issues
    query = arel_table.join(TableReferences.issues).on(TableReferences.issues[:id].eq(arel_table[:issue_id])).
            join(TableReferences.issue_metrics).on(TableReferences.issues[:id].eq(TableReferences.issue_metrics[:issue_id])).
            where(TableReferences.issues[:project_id].eq(@project.id)).
            where(TableReferences.issues[:deleted_at].eq(nil)).
            where(TableReferences.issues[:created_at].gteq(@from))

    # Load merge_requests
    query = query.join(TableReferences.merge_requests, Arel::Nodes::OuterJoin).
            on(TableReferences.merge_requests[:id].eq(arel_table[:merge_request_id])).
            join(TableReferences.merge_request_metrics).
            on(TableReferences.merge_requests[:id].eq(TableReferences.merge_request_metrics[:merge_request_id]))

    # Limit to merge requests that have been deployed to production after `@from`
    query.where(TableReferences.merge_request_metrics[:first_deployed_to_production_at].gteq(@from))
  end

  def run_query(query)
    query = query.to_sql unless query.is_a?(String)
    ActiveRecord::Base.connection.execute(query)
  end
end
