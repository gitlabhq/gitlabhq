# frozen_string_literal: true

class PrepareAsyncMrContextCommitDiffFilesProjectIdValidation < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/221390 will follow
  # as soon as the validation is executed on .com.
  CONSTRAINT_NAME = 'check_90390c308c'

  def up
    prepare_async_check_constraint_validation :merge_request_context_commit_diff_files, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :merge_request_context_commit_diff_files, name: CONSTRAINT_NAME
  end
end
