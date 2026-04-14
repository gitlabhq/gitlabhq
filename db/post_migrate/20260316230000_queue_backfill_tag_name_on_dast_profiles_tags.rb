# frozen_string_literal: true

class QueueBackfillTagNameOnDastProfilesTags < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.11'

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  MIGRATION = 'BackfillTagNameOnDastProfilesTags'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 1_000

  def up
    queue_batched_background_migration(
      MIGRATION,
      :dast_profiles_tags,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :dast_profiles_tags, :id, [])
  end
end
