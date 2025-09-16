# frozen_string_literal: true

class AddOrganizationIndexToJiraConnectInstallations < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'index_jira_connect_installations_on_organization_id'

  milestone '18.5'
  disable_ddl_transaction!

  def up
    add_concurrent_index :jira_connect_installations, :organization_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :jira_connect_installations, :organization_id, name: INDEX_NAME
  end
end
