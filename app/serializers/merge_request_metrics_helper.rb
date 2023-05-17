# frozen_string_literal: true

module MergeRequestMetricsHelper
  # There are cases where where metrics object doesn't exist and it needs to be rebuilt.
  # TODO: Once https://gitlab.com/gitlab-org/gitlab/-/issues/342508 has been resolved and
  # all merge requests have metrics we can remove this helper method.
  def build_metrics(merge_request)
    # There's no need to query and serialize metrics data for merge requests that are not
    # merged or closed.
    return unless merge_request.merged? || merge_request.closed?
    return merge_request.metrics if merge_request.merged? && merge_request.metrics&.merged_by_id
    return merge_request.metrics if merge_request.closed? && merge_request.metrics&.latest_closed_by_id

    build_metrics_from_events(merge_request)
  end

  private

  def build_metrics_from_events(merge_request)
    closed_event = merge_request.closed_event
    merge_event = merge_request.merge_event

    MergeRequest::Metrics.new(
      latest_closed_at: closed_event&.updated_at,
      latest_closed_by: closed_event&.author,
      merged_at: merge_event&.updated_at,
      merged_by: merge_event&.author
    )
  end
end
