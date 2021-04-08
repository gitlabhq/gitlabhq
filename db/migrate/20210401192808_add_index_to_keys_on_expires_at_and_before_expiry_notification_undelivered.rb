# frozen_string_literal: true

class AddIndexToKeysOnExpiresAtAndBeforeExpiryNotificationUndelivered < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'idx_keys_expires_at_and_before_expiry_notification_undelivered'
  disable_ddl_transaction!

  def up
    add_concurrent_index :keys,
                         "date(timezone('UTC', expires_at)), before_expiry_notification_delivered_at",
                         where: 'before_expiry_notification_delivered_at IS NULL', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name(:keys, INDEX_NAME)
  end
end
