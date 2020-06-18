# frozen_string_literal: true

class AddErrorMessageColumnToJiraImports < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  def up
    unless column_exists?(:jira_imports, :error_message)
      add_column :jira_imports, :error_message, :text
    end

    add_text_limit :jira_imports, :error_message, 1000
  end

  def down
    return unless column_exists?(:jira_imports, :error_message)

    remove_column :jira_imports, :error_message
  end
end
