# frozen_string_literal: true

class DropIssuesHealthStatusIndex < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  disable_ddl_transaction!

  INDEX_NAME = 'index_issues_on_project_health_status_desc_work_item_type'
  COLUMNS = %i[project_id health_status id state_id work_item_type_id]
  ORDER = { health_status: 'DESC NULLS LAST', id: 'DESC' }

  def up
    remove_concurrent_index_by_name :issues, name: INDEX_NAME
  end

  def down
    add_concurrent_index :issues, COLUMNS, name: INDEX_NAME, order: ORDER
  end
end
