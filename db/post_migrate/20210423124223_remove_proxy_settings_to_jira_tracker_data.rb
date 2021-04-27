# frozen_string_literal: true

class RemoveProxySettingsToJiraTrackerData < ActiveRecord::Migration[6.0]
  def change
    remove_column :jira_tracker_data, :encrypted_proxy_address, :text
    remove_column :jira_tracker_data, :encrypted_proxy_address_iv, :text
    remove_column :jira_tracker_data, :encrypted_proxy_port, :text
    remove_column :jira_tracker_data, :encrypted_proxy_port_iv, :text
    remove_column :jira_tracker_data, :encrypted_proxy_username, :text
    remove_column :jira_tracker_data, :encrypted_proxy_username_iv, :text
    remove_column :jira_tracker_data, :encrypted_proxy_password, :text
    remove_column :jira_tracker_data, :encrypted_proxy_password_iv, :text
  end
end
