# frozen_string_literal: true

class DropTempIndexTimelogsIssueAndMrMissing < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'tmp_idx_timelogs_issue_mr_missing'
  disable_ddl_transaction!
  milestone '18.5'

  def up
    remove_concurrent_index :timelogs, :id, name: INDEX_NAME
  end

  def down
    add_concurrent_index :timelogs,
      :id,
      name: INDEX_NAME,
      where: 'issue_id IS NULL AND merge_request_id IS NULL'
  end
end
