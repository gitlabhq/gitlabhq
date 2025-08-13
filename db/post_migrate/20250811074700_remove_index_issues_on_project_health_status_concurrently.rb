# frozen_string_literal: true

class RemoveIndexIssuesOnProjectHealthStatusConcurrently < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  INDEX_NAME = 'index_issues_on_project_health_status_asc_work_item_type'
  COLUMNS = [:project_id, :health_status, :id, :state_id, :work_item_type_id]

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :issues, name: INDEX_NAME
  end

  def down
    add_concurrent_index :issues, COLUMNS, order: { id: :desc }, name: INDEX_NAME
  end
end
