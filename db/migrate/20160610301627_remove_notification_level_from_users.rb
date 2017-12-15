# rubocop:disable Migration/RemoveColumn
class RemoveNotificationLevelFromUsers < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  def change
    remove_column :users, :notification_level, :integer
  end
end
