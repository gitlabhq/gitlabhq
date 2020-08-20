# frozen_string_literal: true

class AddIssueTypeIndexToIssues < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  INCIDENT_TYPE = 1
  INDEX_NAME    = 'index_issues_on_incident_issue_type'

  def up
    add_concurrent_index :issues,
                         :issue_type, where: "issue_type = #{INCIDENT_TYPE}",
                         name: INDEX_NAME
  end

  def down
    remove_concurrent_index :issues, :issue_type
  end
end
