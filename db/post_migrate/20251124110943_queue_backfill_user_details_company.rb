# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/database/batched_background_migrations.html
# for more information on when/how to queue batched background migrations

# Update below commented lines with appropriate values.

class QueueBackfillUserDetailsCompany < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  # Select the applicable gitlab schema for your batched background migration
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillUserDetailsCompany"
  BATCH_SIZE = 100_000
  SUB_BATCH_SIZE = 1000

  def up
    queue_batched_background_migration(
      MIGRATION,
      :user_details,
      :user_id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :user_details, :user_id, [])
  end
end
