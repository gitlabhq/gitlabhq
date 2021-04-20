# frozen_string_literal: true

class AddIndexToKeysOnExpiresAtAndExpiryNotificationUndelivered < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_keys_on_expires_at_and_expiry_notification_undelivered'
  disable_ddl_transaction!

  def up
    add_concurrent_index :keys,
                         "date(timezone('UTC', expires_at)), expiry_notification_delivered_at",
                         where: 'expiry_notification_delivered_at IS NULL', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name(:keys, INDEX_NAME)
  end
end
