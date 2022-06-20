# frozen_string_literal: true

class AddJiraConnectApplicationIdApplicationSetting < Gitlab::Database::Migration[2.0]
  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20220513114850_add_text_limit_to_jira_connect_application_id_application_setting.rb
  def change
    add_column :application_settings, :jira_connect_application_key, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
