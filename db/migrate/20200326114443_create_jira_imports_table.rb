# frozen_string_literal: true

class CreateJiraImportsTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  # rubocop:disable Migration/PreventStrings
  def change
    create_table :jira_imports do |t|
      t.integer :project_id, null: false, limit: 8
      t.integer :user_id, limit: 8
      t.integer :label_id, limit: 8
      t.timestamps_with_timezone
      t.datetime_with_timezone :finished_at
      t.integer :jira_project_xid, null: false, limit: 8
      t.integer :total_issue_count, null: false, default: 0, limit: 4
      t.integer :imported_issues_count, null: false, default: 0, limit: 4
      t.integer :failed_to_import_count, null: false, default: 0, limit: 4
      t.integer :status, limit: 2, null: false, default: 0
      t.string :jid, limit: 255
      t.string :jira_project_key, null: false, limit: 255
      t.string :jira_project_name, null: false, limit: 255
    end

    add_index :jira_imports, [:project_id, :jira_project_key], name: 'index_jira_imports_on_project_id_and_jira_project_key'
  end
  # rubocop:enable Migration/PreventStrings
end
