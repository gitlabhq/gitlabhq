# frozen_string_literal: true

class AddEpicIssueCompositeIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_epic_issues_on_epic_id_and_issue_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :epic_issues, [:epic_id, :issue_id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :epic_issues, INDEX_NAME
  end
end
