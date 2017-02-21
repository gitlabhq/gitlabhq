class RemoveInactiveJiraServiceProperties < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON = "Removes all inactive jira_service properties".freeze

  def up
    execute("UPDATE services SET properties = '{}' WHERE services.type = 'JiraService' and services.active = false")
  end
end
