# frozen_string_literal: true

class AddIndexOnJiraConnectInstallationsInstanceUrl < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_jira_connect_installations_on_instance_url'

  def up
    add_concurrent_index :jira_connect_installations, :instance_url, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :jira_connect_installations, name: INDEX_NAME
  end
end
