# frozen_string_literal: true

class BackfillNamespaceIdOnIssues < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  MIGRATION = 'BackfillProjectNamespaceOnIssues'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 500
  MAX_BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 10

  def up
    queue_batched_background_migration(
      MIGRATION,
      :issues,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :issues, :id, [])
  end
end
