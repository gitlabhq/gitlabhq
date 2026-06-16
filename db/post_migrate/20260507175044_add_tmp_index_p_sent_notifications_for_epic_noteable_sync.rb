# frozen_string_literal: true

class AddTmpIndexPSentNotificationsForEpicNoteableSync < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '19.0'
  disable_ddl_transaction!

  PARTITIONED_INDEX_NAME = 'tmp_idx_p_sent_notifications_on_noteable_id_for_epics'

  def up
    add_concurrent_partitioned_index :p_sent_notifications,
      :noteable_id,
      where: "noteable_type = 'Epic'",
      name: PARTITIONED_INDEX_NAME
  end

  def down
    remove_concurrent_partitioned_index_by_name :p_sent_notifications, PARTITIONED_INDEX_NAME
  end
end
