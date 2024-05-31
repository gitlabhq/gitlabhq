# frozen_string_literal: true

class QueueBackfillRemoteDevelopmentAgentConfigsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillRemoteDevelopmentAgentConfigsProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :remote_development_agent_configs,
      :id,
      :project_id,
      :cluster_agents,
      :project_id,
      :cluster_agent_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :remote_development_agent_configs,
      :id,
      [
        :project_id,
        :cluster_agents,
        :project_id,
        :cluster_agent_id
      ]
    )
  end
end
