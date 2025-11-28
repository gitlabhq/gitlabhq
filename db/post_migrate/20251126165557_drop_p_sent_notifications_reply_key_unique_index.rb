# frozen_string_literal: true

class DropPSentNotificationsReplyKeyUniqueIndex < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::IndexHelpers

  INDEX_NAME = 'index_p_sent_notifications_on_reply_key_partition_unique'

  disable_ddl_transaction!
  milestone '18.7'

  def up
    remove_concurrent_partitioned_index_by_name :p_sent_notifications, INDEX_NAME
  end

  def down
    add_concurrent_partitioned_index :p_sent_notifications,
      [:reply_key, :partition],
      unique: true,
      name: INDEX_NAME
  end
end
