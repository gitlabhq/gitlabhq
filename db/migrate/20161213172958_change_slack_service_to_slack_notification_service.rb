class ChangeSlackServiceToSlackNotificationService < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # This migration is a no-op, as it existed in an RC but was then moved:
  #   db/post_migrate/20161220101029_change_slack_service_to_slack_notification_service_in_batches.rb
  def change
  end
end
