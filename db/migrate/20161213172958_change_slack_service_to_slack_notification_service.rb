class ChangeSlackServiceToSlackNotificationService < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON = 'Rename SlackService to SlackNotificationService'

  def up
    execute("UPDATE services SET type = 'SlackNotificationService' WHERE type = 'SlackService'")
  end

  def down
    execute("UPDATE services SET type = 'SlackService' WHERE type = 'SlackNotificationService'")
  end
end
