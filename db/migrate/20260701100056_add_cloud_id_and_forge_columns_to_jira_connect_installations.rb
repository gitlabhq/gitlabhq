# frozen_string_literal: true

class AddCloudIdAndForgeColumnsToJiraConnectInstallations < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  def up
    with_lock_retries do
      add_column :jira_connect_installations, :cloud_id, :text, if_not_exists: true
      add_column :jira_connect_installations, :jira_api_base_url, :text, if_not_exists: true
      add_column :jira_connect_installations, :encrypted_forge_system_token, :text, if_not_exists: true
      add_column :jira_connect_installations, :encrypted_forge_system_token_iv, :text, if_not_exists: true
    end

    add_text_limit :jira_connect_installations, :cloud_id, 255
    add_text_limit :jira_connect_installations, :jira_api_base_url, 512
    add_text_limit :jira_connect_installations, :encrypted_forge_system_token, 8192
    add_text_limit :jira_connect_installations, :encrypted_forge_system_token_iv, 255
  end

  def down
    with_lock_retries do
      remove_column :jira_connect_installations, :cloud_id, if_exists: true
      remove_column :jira_connect_installations, :jira_api_base_url, if_exists: true
      remove_column :jira_connect_installations, :encrypted_forge_system_token, if_exists: true
      remove_column :jira_connect_installations, :encrypted_forge_system_token_iv, if_exists: true
    end
  end
end
