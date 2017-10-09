# rubocop:disable all
class AddNotificationLevelToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :notification_level, :integer, null: false, default: 1
  end
end
