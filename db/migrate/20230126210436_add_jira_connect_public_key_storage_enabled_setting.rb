# frozen_string_literal: true

class AddJiraConnectPublicKeyStorageEnabledSetting < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :jira_connect_public_key_storage_enabled, :boolean, default: false, null: false
  end
end
