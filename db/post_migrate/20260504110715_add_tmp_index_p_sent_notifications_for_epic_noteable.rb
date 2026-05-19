# frozen_string_literal: true

class AddTmpIndexPSentNotificationsForEpicNoteable < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '19.0'

  INDEX_NAME = 'tmp_idx_p_sent_notifications_on_noteable_id_for_epics'

  def up
    # Temporary index to support MigrateEpicSentNotificationsToWorkItems BBM
    # To be removed after BBM finalization https://gitlab.com/gitlab-org/gitlab/-/work_items/454437
    # TODO: Partitioned index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/work_items/596955
    prepare_partitioned_async_index :p_sent_notifications,
      :noteable_id,
      where: "noteable_type = 'Epic'",
      name: INDEX_NAME
  end

  def down
    unprepare_partitioned_async_index :p_sent_notifications, INDEX_NAME
  end
end
