# frozen_string_literal: true

class AddIndexOnUserIdAndNotificationEmailToNotificationSettings < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.4'

  INDEX_NAME = :index_user_id_and_notification_email_to_notification_settings

  def up
    add_concurrent_index :notification_settings, [:user_id, :notification_email, :id], name: INDEX_NAME,
      where: 'notification_email IS NOT NULL'
  end

  def down
    remove_concurrent_index_by_name :notification_settings, INDEX_NAME
  end
end
