# frozen_string_literal: true

class QueueMigrateLegacyOtpSecrets < Gitlab::Database::Migration[2.3]
  milestone '19.4'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "MigrateLegacyOtpSecrets"
  BATCH_SIZE = 3_000

  def up
    queue_batched_background_migration(MIGRATION, :users, :id, batch_size: BATCH_SIZE)
  end

  def down
    delete_batched_background_migration(MIGRATION, :users, :id, [])
  end
end
