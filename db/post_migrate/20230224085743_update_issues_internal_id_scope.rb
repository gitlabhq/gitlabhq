# frozen_string_literal: true

class UpdateIssuesInternalIdScope < Gitlab::Database::Migration[2.1]
  MIGRATION = 'IssuesInternalIdScopeUpdater'
  INTERVAL = 2.minutes
  BATCH_SIZE = 5_000
  MAX_BATCH_SIZE = 20_000
  SUB_BATCH_SIZE = 100

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    queue_batched_background_migration(
      MIGRATION,
      :internal_ids,
      :id,
      job_interval: INTERVAL,
      batch_size: BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :internal_ids, :id, [])
  end
end
