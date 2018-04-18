class AddIssueDueToNotificationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :notification_settings, :issue_due, :boolean
  end
end
