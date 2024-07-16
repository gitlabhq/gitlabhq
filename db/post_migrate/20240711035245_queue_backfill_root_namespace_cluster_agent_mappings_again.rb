# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class QueueBackfillRootNamespaceClusterAgentMappingsAgain < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  # Configure the `gitlab_schema` to perform data manipulation (DML).
  # Visit: https://docs.gitlab.com/ee/development/database/migrations_for_multiple_databases.html
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell
  MIGRATION = "BackfillRootNamespaceClusterAgentMappings"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  # Add dependent 'batched_background_migrations.queued_migration_version' values.
  # DEPENDENT_BATCHED_BACKGROUND_MIGRATIONS = []

  def up
    delete_batched_background_migration(MIGRATION, :remote_development_agent_configs, :id, [])

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
