class RemoveNotificationSettingNotNullConstraints < ActiveRecord::Migration
  def up
    change_column :notification_settings, :source_type, :string, null: true
    change_column :notification_settings, :source_id, :integer, null: true
  end

  def down
    change_column :notification_settings, :source_type, :string, null: false
    change_column :notification_settings, :source_id, :integer, null: false
  end
end
