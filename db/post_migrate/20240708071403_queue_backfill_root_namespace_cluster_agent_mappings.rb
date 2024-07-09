# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/database/batched_background_migrations.html
# for more information on when/how to queue batched background migrations

# Update below commented lines with appropriate values.

class QueueBackfillRootNamespaceClusterAgentMappings < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell
  MIGRATION = "BackfillRootNamespaceClusterAgentMappings"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    # If you are requeueing an already executed migration, you need to delete the prior batched migration record
    # for the new enqueue to be executed, else, you can delete this line.
    # delete_batched_background_migration(MIGRATION, :remote_development_agent_configs, :id, [])

    queue_batched_background_migration(
      MIGRATION,
      :remote_development_agent_configs,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :remote_development_agent_configs, :id, [])
  end
end
