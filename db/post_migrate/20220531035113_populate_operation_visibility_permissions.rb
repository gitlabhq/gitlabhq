# frozen_string_literal: true

class PopulateOperationVisibilityPermissions < Gitlab::Database::Migration[2.0]
  BATCH_SIZE = 50_000
  MAX_BATCH_SIZE = 50_000
  SUB_BATCH_SIZE = 1_000
  INTERVAL = 2.minutes
  MIGRATION = 'PopulateOperationVisibilityPermissionsFromOperations'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    queue_batched_background_migration(
      MIGRATION,
      :project_features,
      :id,
      job_interval: INTERVAL,
      batch_size: BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :project_features, :id, [])
  end
end
