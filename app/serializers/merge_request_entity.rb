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
  expose :diff_head_sha
  expose :head_pipeline, with: PipelineEntity, as: :pipeline
  expose :merge_commit_message

  expose :work_in_progress?, as: :work_in_progress
  expose :source_branch_exists?, as: :source_branch_exists
  expose :mergeable_discussions_state?, as: :mergeable_discussions_state
  expose :conflicts_can_be_resolved_in_ui?, as: :conflicts_can_be_resolved_in_ui
  expose :branch_missing?, as: :branch_missing
  expose :has_no_commits?, as: :has_no_commits
  expose :can_be_cherry_picked?, as: :can_be_cherry_picked
  expose :cannot_be_merged?, as: :has_conflicts
  expose :can_be_merged?, as: :can_be_merged

  expose :current_user do
    expose :can_create_issue do |merge_request|
      merge_request.project.issues_enabled? &&
        can?(request.current_user, :create_issue, merge_request.project)
    end

    # TODO: @oswaldo, please verify this
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

  expose :target_branch_path do |merge_request|
    namespace_project_branch_path(merge_request.target_project.namespace,
                                  merge_request.target_project,
                                  merge_request.target_branch)
  end

  expose :source_branch_path do |merge_request|
    namespace_project_branch_path(merge_request.source_project.namespace,
                                  merge_request.source_project,
                                  merge_request.source_branch)
  end

  expose :project_archived do |merge_request|
    merge_request.project.archived?
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

  expose :merge_path do |merge_request|
    merge_namespace_project_merge_request_path(merge_request.project.namespace,
                                               merge_request.project,
                                               merge_request)
  end

  expose :merge_commit_message_with_description do |merge_request|
    merge_request.merge_commit_message(include_description: true)
  end

  expose :diverged_commits_count do |merge_request|
    merge_request.open? &&
      merge_request.diverged_from_target_branch? ?
        merge_request.diverged_commits_count : 0
  end

  expose :email_patches_path do |merge_request|
    namespace_project_merge_request_path(merge_request.target_project.namespace,
                                         merge_request.target_project,
                                         merge_request,
                                         format: :patch)
  end

  expose :plain_diff_path do |merge_request|
    namespace_project_merge_request_path(merge_request.target_project.namespace,
                                         merge_request.target_project,
                                         merge_request,
                                         format: :diff)
  end

  expose :only_allow_merge_if_pipeline_succeeds do |merge_request|
    merge_request.project.only_allow_merge_if_pipeline_succeeds?
  end

  # TODO: @oswaldo, please verify this
  expose :create_issue_to_resolve_discussions_path do |merge_request|
    new_namespace_project_issue_path(merge_request.project.namespace,
                                     merge_request.project,
                                     merge_request_for_resolving_discussions: merge_request.iid)
  end
end
