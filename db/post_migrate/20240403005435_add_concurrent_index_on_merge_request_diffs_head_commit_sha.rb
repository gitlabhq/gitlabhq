# frozen_string_literal: true

class AddConcurrentIndexOnMergeRequestDiffsHeadCommitSha < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  disable_ddl_transaction!

  TABLE_NAME = :merge_request_diffs
  INDEX_NAME = 'index_on_merge_request_diffs_head_commit_sha'

  def up
    add_concurrent_index TABLE_NAME, :head_commit_sha, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
