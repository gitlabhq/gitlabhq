class AddNotificationLevelToUser < ActiveRecord::Migration
  def change
    add_column :users, :notification_level, :integer, null: false, default: 1
  end
end
