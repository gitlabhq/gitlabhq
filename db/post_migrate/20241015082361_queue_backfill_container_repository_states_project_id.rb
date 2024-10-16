# frozen_string_literal: true

class QueueBackfillContainerRepositoryStatesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillContainerRepositoryStatesProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :container_repository_states,
      :container_repository_id,
      :project_id,
      :container_repositories,
      :project_id,
      :container_repository_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :container_repository_states,
      :container_repository_id,
      [
        :project_id,
        :container_repositories,
        :project_id,
        :container_repository_id
      ]
    )
  end
end
