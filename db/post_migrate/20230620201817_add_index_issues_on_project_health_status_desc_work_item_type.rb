# frozen_string_literal: true

class AddIndexIssuesOnProjectHealthStatusDescWorkItemType < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_issues_on_project_health_status_desc_work_item_type'

  disable_ddl_transaction!

  def up
    add_concurrent_index :issues,
      [:project_id, :health_status, :id, :state_id, :work_item_type_id],
      order: { health_status: 'DESC NULLS LAST', id: :desc },
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :issues, INDEX_NAME
  end
end
