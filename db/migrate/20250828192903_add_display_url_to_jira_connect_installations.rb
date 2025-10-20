# frozen_string_literal: true

class AddDisplayUrlToJiraConnectInstallations < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  def up
    add_column :jira_connect_installations, :display_url, :text, if_not_exists: true
    add_text_limit :jira_connect_installations, :display_url, 255
  end

  def down
    remove_column :jira_connect_installations, :display_url, if_exists: true
  end
end
