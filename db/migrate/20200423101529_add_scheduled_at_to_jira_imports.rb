# frozen_string_literal: true

class AddScheduledAtToJiraImports < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :jira_imports, :scheduled_at, :datetime_with_timezone
  end
end
