# frozen_string_literal: true

class BackfillProjectStatisticsStorageSizeWithoutUploadsSize < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  DELAY_INTERVAL = 2.minutes.to_i
  BATCH_SIZE = 500
  MIGRATION_CLASS = 'BackfillProjectStatisticsStorageSizeWithoutUploadsSize'
  SUB_BATCH_SIZE = 100

  disable_ddl_transaction!

  def up
    return unless Gitlab.dev_or_test_env? || Gitlab.org_or_com?

    queue_batched_background_migration(
      MIGRATION_CLASS,
      :project_statistics,
      :project_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    return unless Gitlab.dev_or_test_env? || Gitlab.org_or_com?

    delete_batched_background_migration(MIGRATION_CLASS, :project_statistics, :project_id, [])
  end
end
