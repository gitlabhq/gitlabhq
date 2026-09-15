# frozen_string_literal: true

class AddForgeInstallationXidToJiraConnectInstallations < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.4'

  INDEX_NAME = 'index_jira_connect_installations_on_forge_installation_xid'

  def up
    with_lock_retries do
      add_column :jira_connect_installations, :forge_installation_xid, :text, if_not_exists: true
    end

    add_text_limit :jira_connect_installations, :forge_installation_xid, 255

    add_concurrent_index :jira_connect_installations, :forge_installation_xid,
      unique: true, where: 'forge_installation_xid IS NOT NULL', name: INDEX_NAME
  end

  def down
    with_lock_retries do
      remove_column :jira_connect_installations, :forge_installation_xid, if_exists: true
    end
  end
end
