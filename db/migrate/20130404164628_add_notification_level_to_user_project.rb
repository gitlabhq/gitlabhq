# rubocop:disable all
class AddNotificationLevelToUserProject < ActiveRecord::Migration[4.2]
  def change
    add_column :users_projects, :notification_level, :integer, null: false, default: 3
  end
end
