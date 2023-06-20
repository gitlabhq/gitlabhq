# frozen_string_literal: true

class PrepareIndexIssuesOnProjectHealthStatusAscWorkItemType < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_issues_on_project_health_status_asc_work_item_type'

  def up
    prepare_async_index :issues,
      [:project_id, :health_status, :id, :state_id, :work_item_type_id],
      order: { health_status: 'ASC NULLS LAST', id: :desc },
      name: INDEX_NAME
  end

  def down
    unprepare_async_index :issues, INDEX_NAME
  end
end
