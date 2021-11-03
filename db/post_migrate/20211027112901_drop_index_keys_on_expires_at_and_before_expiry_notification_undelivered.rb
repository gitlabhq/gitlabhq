# frozen_string_literal: true

class DropIndexKeysOnExpiresAtAndBeforeExpiryNotificationUndelivered < Gitlab::Database::Migration[1.0]
  DOWNTIME = false
  INDEX_NAME = 'index_keys_on_expires_at_and_expiry_notification_undelivered'
  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name(:keys, INDEX_NAME)
  end

  def down
    add_concurrent_index :keys,
                         "date(timezone('UTC', expires_at)), expiry_notification_delivered_at",
                         where: 'expiry_notification_delivered_at IS NULL', name: INDEX_NAME
  end
end
