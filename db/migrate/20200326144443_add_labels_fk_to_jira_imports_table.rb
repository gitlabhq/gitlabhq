# frozen_string_literal: true

class AddLabelsFkToJiraImportsTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_foreign_key :jira_imports, :labels, on_delete: :nullify
    end
  end

  def down
    with_lock_retries do
      remove_foreign_key :jira_imports, :labels
    end
  end
end
