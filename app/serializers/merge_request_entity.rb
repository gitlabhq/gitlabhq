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

  expose :work_in_progress do |merge_request|
    merge_request.work_in_progress?
  end

  expose :source_branch_exists do |merge_request|
    merge_request.source_branch_exists?
  end

  expose :can_remove_source_branch do |merge_request|
    merge_request.can_remove_source_branch?(request.current_user)
  end
end
