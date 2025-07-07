# frozen_string_literal: true

class QueueEncryptMissedCiRunnerTokens < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = "EncryptMissedCiRunnerTokens"

  def up
    queue_batched_background_migration(
      MIGRATION,
      :ci_runners,
      :id
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :ci_runners, :id, [])
  end
end
