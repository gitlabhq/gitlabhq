class MergeRequestWidgetEntity < IssuableEntity
  expose :state
  expose :in_progress_merge_commit_sha
  expose :merge_commit_sha
  expose :merge_error
  expose :merge_params
  expose :merge_status
  expose :merge_user_id
  expose :merge_when_pipeline_succeeds
  expose :source_branch
  expose :source_project_id
  expose :target_branch
  expose :target_project_id
  expose :allow_maintainer_to_push

  expose :should_be_rebased?, as: :should_be_rebased
  expose :ff_only_enabled do |merge_request|
    merge_request.project.merge_requests_ff_only_enabled
  end

  expose :metrics do |merge_request|
    metrics = build_metrics(merge_request)

    MergeRequestMetricsEntity.new(metrics).as_json
  end

  expose :rebase_commit_sha
  expose :rebase_in_progress?, as: :rebase_in_progress

  expose :can_push_to_source_branch do |merge_request|
    presenter(merge_request).can_push_to_source_branch?
  end

  expose :rebase_path do |merge_request|
    presenter(merge_request).rebase_path
  end

  # User entities
  expose :merge_user, using: UserEntity

  # Diff sha's
  expose :diff_head_sha do |merge_request|
    merge_request.diff_head_sha.presence
  end

  expose :merge_commit_message
  expose :actual_head_pipeline, with: PipelineDetailsEntity, as: :pipeline

  # Booleans
  expose :merge_ongoing?, as: :merge_ongoing
  expose :work_in_progress?, as: :work_in_progress
  expose :source_branch_exists?, as: :source_branch_exists

  expose :mergeable_discussions_state?, as: :mergeable_discussions_state do |merge_request|
    # This avoids calling MergeRequest#mergeable_discussions_state without
    # considering the state of the MR first. If a MR isn't mergeable, we can
    # safely short-circuit it.
    if merge_request.mergeable_state?(skip_ci_check: true, skip_discussions_check: true)
      merge_request.mergeable_discussions_state?
    else
      false
    end
  end

  expose :branch_missing?, as: :branch_missing
  expose :commits_count
  expose :cannot_be_merged?, as: :has_conflicts
  expose :can_be_merged?, as: :can_be_merged
  expose :mergeable?, as: :mergeable
  expose :remove_source_branch?, as: :remove_source_branch

  expose :project_archived do |merge_request|
    merge_request.project.archived?
  end

  expose :only_allow_merge_if_pipeline_succeeds do |merge_request|
    merge_request.project.only_allow_merge_if_pipeline_succeeds?
  end

  # CI related
  expose :has_ci?, as: :has_ci
  expose :ci_status do |merge_request|
    presenter(merge_request).ci_status
  end

  expose :issues_links do
    expose :assign_to_closing do |merge_request|
      presenter(merge_request).assign_to_closing_issues_link
    end

    expose :closing do |merge_request|
      presenter(merge_request).closing_issues_links
    end

    expose :mentioned_but_not_closing do |merge_request|
      presenter(merge_request).mentioned_issues_links
    end
  end

  expose :source_branch_with_namespace_link do |merge_request|
    presenter(merge_request).source_branch_with_namespace_link
  end

  expose :source_branch_path do |merge_request|
    presenter(merge_request).source_branch_path
  end

  expose :current_user do
    expose :can_remove_source_branch do |merge_request|
      merge_request.source_branch_exists? && merge_request.can_remove_source_branch?(current_user)
    end

    expose :can_revert_on_current_merge_request do |merge_request|
      presenter(merge_request).can_revert_on_current_merge_request?
    end

    expose :can_cherry_pick_on_current_merge_request do |merge_request|
      presenter(merge_request).can_cherry_pick_on_current_merge_request?
    end

    expose :can_create_note do |issue|
      can?(request.current_user, :create_note, issue.project)
    end

    expose :can_update do |issue|
      can?(request.current_user, :update_issue, issue)
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

  expose :new_blob_path do |merge_request|
    if presenter(merge_request).can_push_to_source_branch?
      project_new_blob_path(merge_request.source_project, merge_request.source_branch)
    end
  end

  expose :conflict_resolution_path do |merge_request|
    presenter(merge_request).conflict_resolution_path
  end

  expose :remove_wip_path do |merge_request|
    presenter(merge_request).remove_wip_path
  end

  expose :cancel_merge_when_pipeline_succeeds_path do |merge_request|
    presenter(merge_request).cancel_merge_when_pipeline_succeeds_path
  end

  expose :create_issue_to_resolve_discussions_path do |merge_request|
    presenter(merge_request).create_issue_to_resolve_discussions_path
  end

  expose :merge_path do |merge_request|
    presenter(merge_request).merge_path
  end

  expose :cherry_pick_in_fork_path do |merge_request|
    presenter(merge_request).cherry_pick_in_fork_path
  end

  expose :revert_in_fork_path do |merge_request|
    presenter(merge_request).revert_in_fork_path
  end

  expose :email_patches_path do |merge_request|
    project_merge_request_path(merge_request.project, merge_request, format: :patch)
  end

  expose :plain_diff_path do |merge_request|
    project_merge_request_path(merge_request.project, merge_request, format: :diff)
  end

  expose :status_path do |merge_request|
    project_merge_request_path(merge_request.target_project, merge_request, format: :json)
  end

  expose :ci_environments_status_path do |merge_request|
    ci_environments_status_project_merge_request_path(merge_request.project, merge_request)
  end

  expose :merge_commit_message_with_description do |merge_request|
    merge_request.merge_commit_message(include_description: true)
  end

  expose :diverged_commits_count do |merge_request|
    if merge_request.open? && merge_request.diverged_from_target_branch?
      merge_request.diverged_commits_count
    else
      0
    end
  end

  expose :create_note_path do |merge_request|
    project_notes_path(merge_request.project, target_type: 'merge_request', target_id: merge_request.id)
  end

  expose :commit_change_content_path do |merge_request|
    commit_change_content_project_merge_request_path(merge_request.project, merge_request)
  end

  # Custom CI path
  #
  expose :has_new_gitlab_ci_yaml do |merge_request|
    merge_request.merge_request_diff.merge_request_diff_files.where(new_path: '.gitlab-ci.yml', new_file: true).any?
  end

  expose :project_ci_config_path do |merge_request|
    merge_request.project.ci_config_path
  end

  expose :has_new_custom_ci_config_yaml do |merge_request|
    presenter(merge_request).has_new_custom_ci_config_yaml?
  end

  private

  delegate :current_user, to: :request

  def presenter(merge_request)
    @presenters ||= {}
    @presenters[merge_request] ||= MergeRequestPresenter.new(merge_request, current_user: current_user)
  end

  # Once SchedulePopulateMergeRequestMetricsWithEventsData fully runs,
  # we can remove this method and just serialize MergeRequest#metrics
  # instead. See https://gitlab.com/gitlab-org/gitlab-ce/issues/41587
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
