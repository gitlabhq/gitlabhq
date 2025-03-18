# frozen_string_literal: true

class AddMergeRequestContextCommitDiffFilesProjectIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :merge_request_context_commit_diff_files, :projects, column: :project_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :merge_request_context_commit_diff_files, column: :project_id
    end
  end
end
