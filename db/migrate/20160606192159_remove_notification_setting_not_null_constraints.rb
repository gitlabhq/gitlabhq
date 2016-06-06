class RemoveNotificationSettingNotNullConstraints < ActiveRecord::Migration
  def up
    change_column :notification_settings, :source_type, :string, null: true
    change_column :notification_settings, :source_id, :integer, null: true
    change_column :users, :notification_level, :integer, null: true
  end
end
