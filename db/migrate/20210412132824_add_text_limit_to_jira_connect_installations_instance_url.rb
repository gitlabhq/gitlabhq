# frozen_string_literal: true

class AddTextLimitToJiraConnectInstallationsInstanceUrl < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_text_limit :jira_connect_installations, :instance_url, 255
  end

  def down
    remove_text_limit :jira_connect_installations, :instance_url
  end
end
