# frozen_string_literal: true

class RecreatePSentNotificationsReplyKeyIndex < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::IndexHelpers

  INDEX_NAME = 'index_p_sent_notifications_on_reply_key'

  disable_ddl_transaction!
  milestone '18.8'

  def up
    add_concurrent_partitioned_index :p_sent_notifications, :reply_key, name: INDEX_NAME
  end

  def down
    remove_concurrent_partitioned_index_by_name :p_sent_notifications, INDEX_NAME
  end
end
