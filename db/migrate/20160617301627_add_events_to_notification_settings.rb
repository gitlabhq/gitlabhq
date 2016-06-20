class AddEventsToNotificationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  def change
    add_column :notification_settings, :events, :text
  end
end
