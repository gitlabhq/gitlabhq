# frozen_string_literal: true

class QueueResetStatusOnContainerRepositories < Gitlab::Database::Migration[2.0]
  MIGRATION = 'ResetStatusOnContainerRepositories'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 50

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    return unless ::Gitlab.config.registry.enabled

    queue_batched_background_migration(
      MIGRATION,
      :container_repositories,
      :id,
      job_interval: DELAY_INTERVAL,
      sub_batch_size: BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :container_repositories, :id, [])
  end
end
