# frozen_string_literal: true

class IndexIssueMetricsOnNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  disable_ddl_transaction!

  INDEX_NAME = 'index_issue_metrics_on_namespace_id'

  def up
    add_concurrent_index :issue_metrics, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :issue_metrics, INDEX_NAME
  end
end
