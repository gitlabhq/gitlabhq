# frozen_string_literal: true

class AddUpdatedAtToJiraConnectInstallations < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    add_timestamps_with_timezone :jira_connect_installations, columns: %i[updated_at], null: true
  end
end
