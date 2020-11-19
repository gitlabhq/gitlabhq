# frozen_string_literal: true

class AddTextLimitToJiraTrackerDataIssuetype < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_text_limit :jira_tracker_data, :vulnerabilities_issuetype, 255
  end

  def down
    remove_text_limit :jira_tracker_data, :vulnerabilities_issuetype
  end
end
