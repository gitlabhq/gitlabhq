# frozen_string_literal: true

class AddProjectsFkToJiraImportsTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_foreign_key :jira_imports, :projects, on_delete: :cascade
    end
  end

  def down
    with_lock_retries do
      remove_foreign_key :jira_imports, :projects
    end
  end
end
