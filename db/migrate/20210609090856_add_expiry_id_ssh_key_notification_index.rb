# frozen_string_literal: true

class AddExpiryIdSshKeyNotificationIndex < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'index_keys_on_expires_at_and_id'

  def up
    add_concurrent_index :keys,
                         "date(timezone('UTC', expires_at)), id",
                         where: 'expiry_notification_delivered_at IS NULL',
                         name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :keys, INDEX_NAME
  end
end
