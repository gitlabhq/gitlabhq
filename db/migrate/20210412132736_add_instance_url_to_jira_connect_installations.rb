# frozen_string_literal: true

class AddInstanceUrlToJiraConnectInstallations < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in db/migrate/20210216163811_add_text_limit_to_jira_connect_installations_instance_url.rb
  def up
    add_column :jira_connect_installations, :instance_url, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns

  def down
    remove_column :jira_connect_installations, :instance_url
  end
end
