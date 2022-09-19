# frozen_string_literal: true

class AddIndexOnIssueHealthStatus < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  TABLE_NAME = :issues
  INDEX_NAME = 'index_issues_on_project_id_health_status_created_at_id'

  def up
    add_concurrent_index TABLE_NAME, [:project_id, :health_status, :created_at, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index TABLE_NAME, [:project_id, :health_status, :created_at, :id], name: INDEX_NAME
  end
end
