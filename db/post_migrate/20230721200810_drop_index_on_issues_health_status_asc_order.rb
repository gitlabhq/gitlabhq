# frozen_string_literal: true

class DropIndexOnIssuesHealthStatusAscOrder < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_on_issues_health_status_asc_order'

  def up
    remove_concurrent_index_by_name :issues, name: INDEX_NAME
  end

  def down
    add_concurrent_index :issues,
      [:project_id, :health_status, :id, :state_id, :issue_type],
      order: { health_status: 'ASC NULLS LAST', id: :desc },
      name: INDEX_NAME
  end
end
