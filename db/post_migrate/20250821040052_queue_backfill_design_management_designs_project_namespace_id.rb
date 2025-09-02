# frozen_string_literal: true

class QueueBackfillDesignManagementDesignsProjectNamespaceId < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillDesignManagementDesignsProjectNamespaceId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 500
  SUB_BATCH_SIZE = 50

  def up
    queue_batched_background_migration(
      MIGRATION,
      :design_management_designs,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :design_management_designs, :id, [])
  end
end
