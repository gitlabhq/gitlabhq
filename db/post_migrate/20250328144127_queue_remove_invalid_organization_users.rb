# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/database/batched_background_migrations.html
# for more information on when/how to queue batched background migrations

# Update below commented lines with appropriate values.

class QueueRemoveInvalidOrganizationUsers < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "RemoveInvalidOrganizationUsers"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 100_000
  SUB_BATCH_SIZE = 1_000

  def up
    queue_batched_background_migration(
      MIGRATION,
      :organization_users,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :organization_users, :id, [])
  end
end
