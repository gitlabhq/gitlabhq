# frozen_string_literal: true

class AddIndexToIncidentIssuesOnProjectAndCreatedAt < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  INCIDENT_TYPE = 1
  OLD_INDEX_NAME = 'index_issues_project_id_issue_type_incident'
  NEW_INDEX_NAME = 'index_issues_on_project_id_and_created_at_issue_type_incident'

  DOWNTIME = false
  disable_ddl_transaction!

  def up
    add_concurrent_index :issues,
                         [:project_id, :created_at],
                         where: "issue_type = #{INCIDENT_TYPE}",
                         name: NEW_INDEX_NAME

    remove_concurrent_index_by_name :issues, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :issues,
                         :project_id,
                         where: "issue_type = #{INCIDENT_TYPE}",
                         name: OLD_INDEX_NAME

    remove_concurrent_index_by_name :issues, NEW_INDEX_NAME
  end
end
