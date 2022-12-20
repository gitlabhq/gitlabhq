# frozen_string_literal: true

class AddIndexForIssuesHealthStatusOrdering < Gitlab::Database::Migration[2.0]
  INDEX_NAME_DESC = 'index_on_issues_health_status_desc_order'
  INDEX_NAME_ASC = 'index_on_issues_health_status_asc_order'

  def up
    prepare_async_index :issues,
      [:project_id, :health_status, :id, :state_id, :issue_type],
      order: { health_status: 'DESC NULLS LAST', id: :desc },
      name: INDEX_NAME_DESC

    prepare_async_index :issues,
      [:project_id, :health_status, :id, :state_id, :issue_type],
      order: { health_status: 'ASC NULLS LAST', id: :desc },
      name: INDEX_NAME_ASC
  end

  def down
    unprepare_async_index :issues, INDEX_NAME_DESC
    unprepare_async_index :issues, INDEX_NAME_ASC
  end
end
