# frozen_string_literal: true

class AddJiraConnectProxyUrlSetting < Gitlab::Database::Migration[2.0]
  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20220920135717_add_textlimit_to_jira_connect_proxy_url_setting.rb
  def change
    add_column :application_settings, :jira_connect_proxy_url, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
