# frozen_string_literal: true

class AddTemporaryIndexToIssueMetrics < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_issue_metrics_first_mentioned_in_commit'

  def up
    add_concurrent_index :issue_metrics, :issue_id, where: 'EXTRACT(YEAR FROM first_mentioned_in_commit_at) > 2019', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :issue_metrics, name: INDEX_NAME
  end
end
