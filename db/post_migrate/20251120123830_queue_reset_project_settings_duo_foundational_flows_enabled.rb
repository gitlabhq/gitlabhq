# frozen_string_literal: true

class QueueResetProjectSettingsDuoFoundationalFlowsEnabled < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = 'ResetProjectSettingsDuoFoundationalFlowsEnabled'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 50_000
  SUB_BATCH_SIZE = 5_000

  def up
    queue_batched_background_migration(
      MIGRATION,
      :project_settings,
      :project_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :project_settings, :project_id, [])
  end
end
