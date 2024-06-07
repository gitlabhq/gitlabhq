# frozen_string_literal: true

class QueueBackfillTerraformStateVersionsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillTerraformStateVersionsProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :terraform_state_versions,
      :id,
      :project_id,
      :terraform_states,
      :project_id,
      :terraform_state_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :terraform_state_versions,
      :id,
      [
        :project_id,
        :terraform_states,
        :project_id,
        :terraform_state_id
      ]
    )
  end
end
