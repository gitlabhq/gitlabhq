class RemoveEventsFromNotificationSettings < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    remove_column :notification_settings, :events, :text
  end
end
