# frozen_string_literal: true

class QueueBackfillPipelineExecutionPoliciesMetadata < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillPipelineExecutionPoliciesMetadata"
  DELAY_INTERVAL = 10.minutes
  BATCH_SIZE = 50
  SUB_BATCH_SIZE = 10
  DEPENDENT_BATCHED_BACKGROUND_MIGRATIONS = ['20250205175341']

  def up
    queue_batched_background_migration(
      MIGRATION,
      :security_policies,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :security_policies, :id, [])
  end
end
