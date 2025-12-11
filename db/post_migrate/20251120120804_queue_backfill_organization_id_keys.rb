# frozen_string_literal: true

class QueueBackfillOrganizationIdKeys < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillOrganizationIdKeys"
  BATCH_SIZE = 2000
  SUB_BATCH_SIZE = 200
  INTERVAL = 30.seconds

  def up
    queue_batched_background_migration(
      MIGRATION,
      :keys,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      job_interval: INTERVAL
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :keys, :id, [])
  end
end
