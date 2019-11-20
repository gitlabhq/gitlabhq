# frozen_string_literal: true

class MergeRequestPollCachedWidgetEntity < IssuableEntity
  expose :auto_merge_enabled
  expose :state
  expose :merge_commit_sha
  expose :short_merge_commit_sha
  expose :merge_error
  expose :merge_status
  expose :merge_user_id
  expose :source_branch
  expose :source_project_id
  expose :target_branch
  expose :target_branch_sha
  expose :target_project_id
  expose :squash
  expose :rebase_in_progress?, as: :rebase_in_progress
  expose :default_squash_commit_message, if: -> (merge_request, _) { merge_request.mergeable? }
  expose :commits_count
  expose :merge_ongoing?, as: :merge_ongoing
  expose :work_in_progress?, as: :work_in_progress
  expose :cannot_be_merged?, as: :has_conflicts
  expose :can_be_merged?, as: :can_be_merged
  expose :remove_source_branch?, as: :remove_source_branch
  expose :source_branch_exists?, as: :source_branch_exists
  expose :branch_missing?, as: :branch_missing

  expose :commits_without_merge_commits, using: MergeRequestWidgetCommitEntity,
    if: -> (merge_request, _) { merge_request.mergeable? } do |merge_request|
    merge_request.recent_commits.without_merge_commits
  end
  expose :diff_head_sha do |merge_request|
    merge_request.diff_head_sha.presence
  end
  expose :metrics do |merge_request|
    metrics = build_metrics(merge_request)

    MergeRequestMetricsEntity.new(metrics).as_json
  end

  expose :diverged_commits_count do |merge_request|
    if merge_request.open? && merge_request.diverged_from_target_branch?
      merge_request.diverged_commits_count
    else
      0
    end
  end

  # Paths
  #
  expose :target_branch_commits_path do |merge_request|
    presenter(merge_request).target_branch_commits_path
  end

  expose :target_branch_tree_path do |merge_request|
    presenter(merge_request).target_branch_tree_path
  end

  expose :merge_commit_path do |merge_request|
    if merge_request.merge_commit_sha
      project_commit_path(merge_request.project, merge_request.merge_commit_sha)
    end
  end

  expose :source_branch_path do |merge_request|
    presenter(merge_request).source_branch_path
  end

  expose :source_branch_with_namespace_link do |merge_request|
    presenter(merge_request).source_branch_with_namespace_link
  end

  private

  delegate :current_user, to: :request

  def presenter(merge_request)
    @presenters ||= {}
    @presenters[merge_request] ||= MergeRequestPresenter.new(merge_request, current_user: current_user) # rubocop: disable CodeReuse/Presenter
  end

  # Once SchedulePopulateMergeRequestMetricsWithEventsData fully runs,
  # we can remove this method and just serialize MergeRequest#metrics
  # instead. See https://gitlab.com/gitlab-org/gitlab-foss/issues/41587
  def build_metrics(merge_request)
    # There's no need to query and serialize metrics data for merge requests that are not
    # merged or closed.
    return unless merge_request.merged? || merge_request.closed?
    return merge_request.metrics if merge_request.merged? && merge_request.metrics&.merged_by_id
    return merge_request.metrics if merge_request.closed? && merge_request.metrics&.latest_closed_by_id

    build_metrics_from_events(merge_request)
  end

  def build_metrics_from_events(merge_request)
    closed_event = merge_request.closed_event
    merge_event = merge_request.merge_event

    MergeRequest::Metrics.new(latest_closed_at: closed_event&.updated_at,
                              latest_closed_by: closed_event&.author,
                              merged_at: merge_event&.updated_at,
                              merged_by: merge_event&.author)
  end
end

MergeRequestPollCachedWidgetEntity.prepend_if_ee('EE::MergeRequestPollCachedWidgetEntity')
