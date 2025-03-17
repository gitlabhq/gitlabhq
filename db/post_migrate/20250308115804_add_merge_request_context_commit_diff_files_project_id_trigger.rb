# frozen_string_literal: true

class AddMergeRequestContextCommitDiffFilesProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def up
    install_sharding_key_assignment_trigger(
      table: :merge_request_context_commit_diff_files,
      sharding_key: :project_id,
      parent_table: :merge_request_context_commits,
      parent_sharding_key: :project_id,
      foreign_key: :merge_request_context_commit_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :merge_request_context_commit_diff_files,
      sharding_key: :project_id,
      parent_table: :merge_request_context_commits,
      parent_sharding_key: :project_id,
      foreign_key: :merge_request_context_commit_id
    )
  end
end
