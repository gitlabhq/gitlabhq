# frozen_string_literal: true

class ReRequeueBackfillProjectsRedirectRoutesNamespaceId < Gitlab::Database::Migration[2.3]
  milestone '18.3'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillProjectsRedirectRoutesNamespaceId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1_000
  MAX_BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 250

  def up
    delete_batched_background_migration(
      MIGRATION,
      :redirect_routes,
      :id,
      []
    )

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
    delete_batched_background_migration(
      MIGRATION,
      :redirect_routes,
      :id,
      []
    )
  end
end
