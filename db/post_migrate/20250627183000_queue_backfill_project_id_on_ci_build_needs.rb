# frozen_string_literal: true

class QueueBackfillProjectIdOnCiBuildNeeds < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = "BackfillProjectIdOnCiBuildNeeds"
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100
  DELAY_INTERVAL = 2.minutes

  def up
    return if Gitlab.com_except_jh?

    queue_batched_background_migration(
      MIGRATION,
      :ci_build_needs,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :ci_build_needs, :id, [])
  end
end
