# frozen_string_literal: true

class DropIndexOnIssuesClosedIncidentsByProjectIdAndClosedAt < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_on_issues_closed_incidents_by_project_id_and_closed_at'

  def up
    remove_concurrent_index_by_name :issues, name: INDEX_NAME
  end

  def down
    add_concurrent_index :issues, [:project_id, :closed_at], where: 'issue_type = 1 AND state_id = 2', name: INDEX_NAME
  end
end
