# frozen_string_literal: true

class DeleteBackfillCiRunnerSemverMigration < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = 'BackfillCiRunnerSemver'

  disable_ddl_transaction!

  def up
    # Disabled background migration introduced in same milestone as it was decided to change approach
    # and the semver column will no longer be needed
    delete_batched_background_migration(MIGRATION, :ci_runners, :id, [])
  end

  def down
    # no-op
  end
end
