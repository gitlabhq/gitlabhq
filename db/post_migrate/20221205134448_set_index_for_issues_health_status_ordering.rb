# frozen_string_literal: true

class SetIndexForIssuesHealthStatusOrdering < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME_DESC = 'index_on_issues_health_status_desc_order'
  INDEX_NAME_ASC = 'index_on_issues_health_status_asc_order'

  def up
    add_concurrent_index :issues,
      [:project_id, :health_status, :id, :state_id, :issue_type],
      order: { health_status: 'DESC NULLS LAST', id: :desc },
      name: INDEX_NAME_DESC

    add_concurrent_index :issues,
      [:project_id, :health_status, :id, :state_id, :issue_type],
      order: { health_status: 'ASC NULLS LAST', id: :desc },
      name: INDEX_NAME_ASC
  end

  def down
    remove_concurrent_index_by_name :issues, INDEX_NAME_DESC
    remove_concurrent_index_by_name :issues, INDEX_NAME_ASC
  end
end
