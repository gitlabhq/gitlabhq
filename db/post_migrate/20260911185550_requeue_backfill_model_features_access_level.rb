# frozen_string_literal: true

# Requeues BackfillModelFeaturesAccessLevel. Its original enqueue (20260617140000)
# was no-oped and the BBM deleted by 20260625005917 when the visibility-based
# access level defaults were reverted; those defaults are back, so it runs again.
class RequeueBackfillModelFeaturesAccessLevel < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillModelFeaturesAccessLevel"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1_000
  SUB_BATCH_SIZE = 100

  def up
    delete_batched_background_migration(MIGRATION, :project_features, :id, [])

    queue_batched_background_migration(
      MIGRATION,
      :project_features,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :project_features, :id, [])
  end
end
