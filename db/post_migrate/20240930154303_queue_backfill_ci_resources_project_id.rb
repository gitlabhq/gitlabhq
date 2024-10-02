# frozen_string_literal: true

class QueueBackfillCiResourcesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = "BackfillCiResourcesProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :ci_resources,
      :id,
      :project_id,
      :ci_resource_groups,
      :project_id,
      :resource_group_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :ci_resources,
      :id,
      [
        :project_id,
        :ci_resource_groups,
        :project_id,
        :resource_group_id
      ]
    )
  end
end
