class RemoveEventsFromNotificationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    remove_column :notification_settings, :events, :text
  end
end
