# frozen_string_literal: true

class DropIndexSentNotificationsOnReplyKeyAsync < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  INDEX_NAME = 'index_sent_notifications_on_reply_key'

  def up
    prepare_async_index_removal :sent_notifications, :reply_key, name: INDEX_NAME
  end

  def down
    unprepare_async_index :sent_notifications, :reply_key, name: INDEX_NAME
  end
end
