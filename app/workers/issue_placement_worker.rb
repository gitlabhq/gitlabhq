# frozen_string_literal: true

class IssuePlacementWorker
  include ApplicationWorker

  idempotent!
  feature_category :issue_tracking
  urgency :high
  worker_resource_boundary :cpu
  weight 2

  # Move at most the most recent 100 issues
  QUERY_LIMIT = 100

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(issue_id)
    issue = Issue.id_in(issue_id).first
    return unless issue

    # Move the most recent 100 unpositioned items to the end.
    # This is to deal with out-of-order execution of the worker,
    # while preserving creation order.
    to_place = Issue
      .relative_positioning_query_base(issue)
      .where(relative_position: nil)
      .order({ created_at: :desc }, { id: :desc })
      .limit(QUERY_LIMIT)

    Issue.move_nulls_to_end(to_place.to_a.reverse)
    Issues::BaseService.new(nil).rebalance_if_needed(to_place.max_by(&:relative_position))
  rescue RelativePositioning::NoSpaceLeft => e
    Gitlab::ErrorTracking.log_exception(e, issue_id: issue_id)
    IssueRebalancingWorker.perform_async(nil, issue.project_id)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
