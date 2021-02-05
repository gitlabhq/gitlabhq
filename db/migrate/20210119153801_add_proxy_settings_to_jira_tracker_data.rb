# frozen_string_literal: true

class AddProxySettingsToJiraTrackerData < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :jira_tracker_data, :encrypted_proxy_address, :text
    add_column :jira_tracker_data, :encrypted_proxy_address_iv, :text
    add_column :jira_tracker_data, :encrypted_proxy_port, :text
    add_column :jira_tracker_data, :encrypted_proxy_port_iv, :text
    add_column :jira_tracker_data, :encrypted_proxy_username, :text
    add_column :jira_tracker_data, :encrypted_proxy_username_iv, :text
    add_column :jira_tracker_data, :encrypted_proxy_password, :text
    add_column :jira_tracker_data, :encrypted_proxy_password_iv, :text
  end
end
