# frozen_string_literal: true

class DropAsyncIssuesHealthStatusIndex < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  INDEX_NAME = 'index_issues_on_project_health_status_desc_work_item_type'
  COLUMNS = %i[project_id health_status id state_id work_item_type_id]
  ORDER = { health_status: 'DESC NULLS LAST', id: 'DESC' }

  def up
    prepare_async_index_removal :issues, COLUMNS, name: INDEX_NAME, order: ORDER
  end

  def down
    unprepare_async_index :issues, COLUMNS, name: INDEX_NAME, order: ORDER
  end
end
