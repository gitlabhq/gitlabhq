# frozen_string_literal: true

class IndexTimelogsIssueMergeRequestBothPresent < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'tmp_idx_timelogs_issue_mr_both_present'

  disable_ddl_transaction!
  milestone '18.5'

  def up
    add_concurrent_index :timelogs,
      :id,
      name: INDEX_NAME,
      where: 'issue_id IS NOT NULL AND merge_request_id IS NOT NULL'
  end

  def down
    remove_concurrent_index :timelogs, :id, name: INDEX_NAME
  end
end
