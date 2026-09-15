# frozen_string_literal: true

class QueueBackfillEmailsOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_user

  MIGRATION = 'BackfillEmailsOrganizationId'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1_000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :emails,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :emails, :id, [])
  end
end
