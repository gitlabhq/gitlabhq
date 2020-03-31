# frozen_string_literal: true

class AddLabelsFkIndexOnJiraImportsTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :jira_imports, :label_id
  end

  def down
    remove_concurrent_index :jira_imports, :label_id
  end
end
