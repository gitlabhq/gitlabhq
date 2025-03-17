# frozen_string_literal: true

class IndexMergeRequestContextCommitDiffFilesOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  disable_ddl_transaction!

  INDEX_NAME = 'index_merge_request_context_commit_diff_files_on_project_id'

  def up
    add_concurrent_index :merge_request_context_commit_diff_files, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :merge_request_context_commit_diff_files, INDEX_NAME
  end
end
