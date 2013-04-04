class AddNotificationLevelToUserProject < ActiveRecord::Migration
  def change
    add_column :users_projects, :notification_level, :integer, null: false, default: 3
  end
end
