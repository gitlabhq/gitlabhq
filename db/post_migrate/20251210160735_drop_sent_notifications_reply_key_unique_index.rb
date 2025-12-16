# frozen_string_literal: true

class DropSentNotificationsReplyKeyUniqueIndex < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    remove_concurrent_index_by_name :sent_notifications, 'index_sent_notifications_on_reply_key'
  end

  def down
    add_concurrent_index :sent_notifications, :reply_key, name: 'index_sent_notifications_on_reply_key', unique: true
  end
end
