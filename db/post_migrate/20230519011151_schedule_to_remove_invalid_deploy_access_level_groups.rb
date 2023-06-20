# frozen_string_literal: true

class ScheduleToRemoveInvalidDeployAccessLevelGroups < Gitlab::Database::Migration[2.1]
  MIGRATION = "RemoveInvalidDeployAccessLevelGroups"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    queue_batched_background_migration(
      MIGRATION,
      :protected_environment_deploy_access_levels,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :protected_environment_deploy_access_levels, :id, [])
  end
end
