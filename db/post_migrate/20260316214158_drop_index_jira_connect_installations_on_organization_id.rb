# frozen_string_literal: true

class DropIndexJiraConnectInstallationsOnOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '18.11'
  disable_ddl_transaction!

  INDEX_NAME = 'index_jira_connect_installations_on_organization_id'

  def up
    remove_concurrent_index_by_name :jira_connect_installations, INDEX_NAME
  end

  def down
    add_concurrent_index :jira_connect_installations, :organization_id, name: INDEX_NAME
  end
end
