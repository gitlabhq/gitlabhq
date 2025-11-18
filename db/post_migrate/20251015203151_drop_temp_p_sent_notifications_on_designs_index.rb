# frozen_string_literal: true

class DropTempPSentNotificationsOnDesignsIndex < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  INDEX_NAME = 'tmp_idx_p_sent_notifications_on_id_for_designs'

  disable_ddl_transaction!
  milestone '18.6'

  def up
    remove_concurrent_partitioned_index_by_name :p_sent_notifications, INDEX_NAME
  end

  def down
    add_concurrent_partitioned_index :p_sent_notifications,
      :id,
      where: "noteable_type = 'DesignManagement::Design'",
      name: INDEX_NAME
  end
end
