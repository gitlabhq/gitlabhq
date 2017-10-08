class AddEventsToNotificationSettings < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  def change
    add_column :notification_settings, :events, :text
  end
end
