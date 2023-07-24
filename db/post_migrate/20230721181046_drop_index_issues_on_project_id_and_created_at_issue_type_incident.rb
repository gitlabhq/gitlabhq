# frozen_string_literal: true

class DropIndexIssuesOnProjectIdAndCreatedAtIssueTypeIncident < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_issues_on_project_id_and_created_at_issue_type_incident'

  def up
    remove_concurrent_index_by_name :issues, name: INDEX_NAME
  end

  def down
    add_concurrent_index :issues, [:project_id, :created_at], where: 'issue_type = 1', name: INDEX_NAME
  end
end
