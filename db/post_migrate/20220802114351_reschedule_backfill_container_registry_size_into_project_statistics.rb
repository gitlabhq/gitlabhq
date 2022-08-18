# frozen_string_literal: true

class RescheduleBackfillContainerRegistrySizeIntoProjectStatistics < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  DELAY_INTERVAL = 2.minutes.to_i
  BATCH_SIZE = 500
  MIGRATION_CLASS = 'BackfillProjectStatisticsContainerRepositorySize'
  BATCH_CLASS_NAME = 'BackfillProjectStatisticsWithContainerRegistrySizeBatchingStrategy'
  SUB_BATCH_SIZE = 100

  disable_ddl_transaction!

  def up
    return unless Gitlab.dev_or_test_env? || Gitlab.com?

    # remove the original migration
    delete_batched_background_migration(MIGRATION_CLASS, :container_repositories, :project_id, [])

    # reschedule the migration
    queue_batched_background_migration(
      MIGRATION_CLASS,
      :container_repositories,
      :project_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      batch_class_name: BATCH_CLASS_NAME,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    return unless Gitlab.dev_or_test_env? || Gitlab.com?

    delete_batched_background_migration(MIGRATION_CLASS, :container_repositories, :project_id, [])
  end
end
