# frozen_string_literal: true

class AddIndexOnMergeRequestDiffsHeadCommitSha < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  disable_ddl_transaction!

  TABLE_NAME = :merge_request_diffs
  INDEX_NAME = 'index_on_merge_request_diffs_head_commit_sha'

  def up
    prepare_async_index TABLE_NAME, :head_commit_sha, name: INDEX_NAME
  end

  def down
    unprepare_async_index TABLE_NAME, :head_commit_sha, name: INDEX_NAME
  end
end
