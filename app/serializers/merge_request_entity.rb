class MergeRequestEntity < IssuableEntity
  include RequestAwareEntity

  expose :author, using: UserEntity

  expose :in_progress_merge_commit_sha
  expose :locked_at
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
  expose :merge_commit_sha
  expose :merge_event
  expose :closed_event
  expose :head_pipeline
  expose :work_in_progress?, as: :work_in_progress
  expose :source_branch_exists?, as: :source_branch_exists
  expose :mergeable_discussions_state?, as: :mergeable_discussions_state
  expose :conflicts_can_be_resolved_in_ui?, as: :conflicts_can_be_resolved_in_ui
  expose :branch_missing?, as: :branch_missing
  expose :has_no_commits?, as: :has_no_commits

  expose :current_user do
    expose :can_create_issue do |merge_request|
      merge_request.project.issues_enabled? &&
        can?(request.current_user, :create_issue, merge_request.project)
    end

    expose :can_update_merge_request do |merge_request|
      merge_request.project.merge_requests_enabled? &&
        can?(request.current_user, :update_merge_request, merge_request.project)
    end

    expose :can_resolve_conflicts do |merge_request|
      merge_request.conflicts_can_be_resolved_by?(request.current_user)
    end

    expose :can_remove_source_branch do |merge_request|
      merge_request.can_remove_source_branch?(request.current_user)
    end

    expose :can_merge do |merge_request|
      merge_request.can_be_merged_by?(request.current_user)
    end

    expose :can_merge_via_cli do |merge_request|
      merge_request.can_be_merged_via_command_line_by?(request.current_user)
    end

    expose :can_revert do |merge_request|
      merge_request.can_be_reverted?(request.current_user)
    end
  end

  expose :can_be_cherry_picked do |merge_request|
    merge_request.can_be_cherry_picked?
  end

  expose :target_branch_path do |merge_request|
    namespace_project_commits_path(merge_request.project.namespace,
                                   merge_request.project,
                                   merge_request.target_branch)
  end

  expose :project_archived do |merge_request|
    merge_request.project.archived?
  end

  expose :has_conflicts do |merge_request|
    merge_request.cannot_be_merged?
  end

  expose :conflict_resolution_ui_path do |merge_request|
    conflicts_namespace_project_merge_request_path(merge_request.project.namespace,
                                                   merge_request.project,
                                                   merge_request)
  end

  expose :remove_wip_path do |merge_request|
    remove_wip_namespace_project_merge_request_path(merge_request.project.namespace,
                                                    merge_request.project,
                                                    merge_request)
  end
end
