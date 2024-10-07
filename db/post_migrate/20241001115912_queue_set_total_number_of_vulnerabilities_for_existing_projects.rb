# frozen_string_literal: true

class QueueSetTotalNumberOfVulnerabilitiesForExistingProjects < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  MIGRATION = "SetTotalNumberOfVulnerabilitiesForExistingProjects"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    delete_batched_background_migration('SetProjectVulnerabilityCount', :project_settings, :project_id, [])

    queue_batched_background_migration(
      MIGRATION,
      :vulnerability_reads,
      :project_id,
      batch_class_name: 'LooseIndexScanBatchingStrategy',
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :vulnerability_reads, :project_id, [])
  end
end
