class AddNotificationLevelToUserGroup < ActiveRecord::Migration
  def change
    add_column :users_groups, :notification_level, :integer, null: false, default: 3
  end
end
