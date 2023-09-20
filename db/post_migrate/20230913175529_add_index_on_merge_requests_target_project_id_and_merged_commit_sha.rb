# frozen_string_literal: true

class AddIndexOnMergeRequestsTargetProjectIdAndMergedCommitSha < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_merge_requests_on_target_project_id_and_merged_commit_sha'
  INDEX_COLUMNS = %i[target_project_id merged_commit_sha]

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_requests, INDEX_COLUMNS, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :merge_requests, name: INDEX_NAME
  end
end
