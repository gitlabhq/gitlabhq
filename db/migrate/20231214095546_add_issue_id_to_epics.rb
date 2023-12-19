# frozen_string_literal: true

class AddIssueIdToEpics < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'index_unique_epics_on_issue_id'

  disable_ddl_transaction!
  milestone '16.7'

  def up
    add_column :epics, :issue_id, :int, if_not_exists: true
    add_concurrent_index :epics, :issue_id, unique: true, name: INDEX_NAME
    add_concurrent_foreign_key(:epics, :issues, column: :issue_id, validate: true)
  end

  def down
    remove_column :epics, :issue_id, if_exists: true
  end
end
