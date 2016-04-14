class AddNotificationSettingIndex < ActiveRecord::Migration
  def change
    add_index :notification_settings, :user_id
    add_index :notification_settings, [:source_id, :source_type]
  end
end
