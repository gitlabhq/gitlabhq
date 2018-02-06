# rubocop:disable all
class AddIndexToNotificationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def change
    add_concurrent_index :notification_settings, [:user_id, :source_id, :source_type], { unique: true, name: "index_notifications_on_user_id_and_source_id_and_source_type" }
  end
end
