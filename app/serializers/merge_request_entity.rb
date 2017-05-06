class MergeRequestEntity < IssuableEntity
<<<<<<< HEAD
  expose :approvals_before_merge
=======
>>>>>>> 6ce1df41e175c7d62ca760b1e66cf1bf86150284
  expose :assignee_id
  expose :in_progress_merge_commit_sha
  expose :locked_at
  expose :merge_commit_sha
  expose :merge_error
  expose :merge_params
  expose :merge_status
  expose :merge_user_id
  expose :merge_when_pipeline_succeeds
  expose :rebase_commit_sha
  expose :rebase_in_progress?, if: { type: :full }
  expose :source_branch
  expose :source_project_id
  expose :target_branch
  expose :target_project_id
end
