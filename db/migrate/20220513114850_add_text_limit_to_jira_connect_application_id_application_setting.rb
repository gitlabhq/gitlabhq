# frozen_string_literal: true

class AddTextLimitToJiraConnectApplicationIdApplicationSetting < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_text_limit :application_settings, :jira_connect_application_key, 255
  end

  def down
    remove_text_limit :application_settings, :jira_connect_application_key
  end
end
