# frozen_string_literal: true

class AddIncidentIssueTypeIndexToIssues < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INCIDENT_ISSUE_TYPE = 1
  INDEX_NAME = 'index_issues_project_id_issue_type_incident'

  def up
    add_concurrent_index :issues, :project_id, where: "issue_type = #{INCIDENT_ISSUE_TYPE}", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name(:issues, INDEX_NAME)
  end
end
