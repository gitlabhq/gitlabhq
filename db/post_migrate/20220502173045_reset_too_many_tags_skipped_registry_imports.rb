# frozen_string_literal: true

class ResetTooManyTagsSkippedRegistryImports < Gitlab::Database::Migration[2.0]
  MIGRATION = 'ResetTooManyTagsSkippedRegistryImports'
  DELAY_INTERVAL = 2.minutes.to_i
  BATCH_SIZE = 10_000

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      define_batchable_model('container_repositories').where(
        migration_state: 'import_skipped',
        migration_skipped_reason: 2
      ),
      MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      track_jobs: true
    )
  end

  def down
    # no-op
  end
end
