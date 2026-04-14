# frozen_string_literal: true

class AddUniqueIndexJiraConnectInstallationsOnOrganizationIdClientKey < Gitlab::Database::Migration[2.3]
  milestone '18.11'
  disable_ddl_transaction!

  INDEX_NAME = 'idx_jira_connect_installations_on_org_id_client_key_uniq'

  def up
    add_concurrent_index :jira_connect_installations,
      [:organization_id, :client_key],
      name: INDEX_NAME,
      unique: true
  end

  def down
    remove_concurrent_index_by_name :jira_connect_installations, INDEX_NAME
  end
end
