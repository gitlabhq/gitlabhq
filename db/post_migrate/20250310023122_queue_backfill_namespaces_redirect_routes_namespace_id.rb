# frozen_string_literal: true

class QueueBackfillNamespacesRedirectRoutesNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillNamespacesRedirectRoutesNamespaceId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1_000
  MAX_BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 250

  def up
    queue_batched_background_migration(
      MIGRATION,
      :redirect_routes,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :redirect_routes, :id, [])
  end
end
