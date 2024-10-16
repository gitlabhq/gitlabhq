# frozen_string_literal: true

class QueueBackfillDependencyProxyBlobStatesGroupId < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillDependencyProxyBlobStatesGroupId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :dependency_proxy_blob_states,
      :dependency_proxy_blob_id,
      :group_id,
      :dependency_proxy_blobs,
      :group_id,
      :dependency_proxy_blob_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :dependency_proxy_blob_states,
      :dependency_proxy_blob_id,
      [
        :group_id,
        :dependency_proxy_blobs,
        :group_id,
        :dependency_proxy_blob_id
      ]
    )
  end
end
