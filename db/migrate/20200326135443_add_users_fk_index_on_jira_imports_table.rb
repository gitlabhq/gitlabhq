# frozen_string_literal: true

class AddUsersFkIndexOnJiraImportsTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :jira_imports, :user_id
  end

  def down
    remove_concurrent_index :jira_imports, :user_id
  end
end
