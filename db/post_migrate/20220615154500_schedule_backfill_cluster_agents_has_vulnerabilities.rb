# frozen_string_literal: true

class ScheduleBackfillClusterAgentsHasVulnerabilities < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  MIGRATION = 'BackfillClusterAgentsHasVulnerabilities'
  DELAY_INTERVAL = 2.minutes

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillVulnerabilityReadsClusterAgent',
      table_name: :vulnerability_reads,
      column_name: :id,
      job_arguments: []
    )

    queue_batched_background_migration(
      MIGRATION,
      :cluster_agents,
      :id,
      job_interval: DELAY_INTERVAL
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :cluster_agents, :id, [])
  end
end
