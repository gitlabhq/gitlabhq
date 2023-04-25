# frozen_string_literal: true

class RemoveIndexOnMergeRequestId < Gitlab::Database::Migration[1.0]
  TABLE = :merge_request_context_commits
  INDEX_NAME = 'index_merge_request_context_commits_on_merge_request_id'
  COLUMN = :merge_request_id

  disable_ddl_transaction!

  def up
    remove_concurrent_index TABLE, COLUMN, name: INDEX_NAME
  end

  def down
    add_concurrent_index TABLE, COLUMN, name: INDEX_NAME
  end
end
