# frozen_string_literal: true

class DropIndexIssuesOnIncidentIssueType < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_issues_on_incident_issue_type'

  def up
    remove_concurrent_index_by_name :issues, name: INDEX_NAME
  end

  def down
    add_concurrent_index :issues, :issue_type, where: 'issue_type = 1', name: INDEX_NAME
  end
end
