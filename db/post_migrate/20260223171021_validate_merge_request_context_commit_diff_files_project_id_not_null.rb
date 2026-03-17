# frozen_string_literal: true

class ValidateMergeRequestContextCommitDiffFilesProjectIdNotNull < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  CONSTRAINT_NAME = :check_90390c308c

  # NOTE: validated asynchronously on GitLab.com in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/221482
  def up
    validate_not_null_constraint :merge_request_context_commit_diff_files, :project_id, constraint_name: CONSTRAINT_NAME
  end

  def down
    # no-op
  end
end
