# frozen_string_literal: true

class RemoveBackfillSecurityProjectTrackedContextsDefaultBranch < Gitlab::Database::Migration[2.3]
  milestone '18.8'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillSecurityProjectTrackedContextsDefaultBranch"

  def up
    delete_batched_background_migration(MIGRATION, :projects, :id, [])
  end

  def down
    # no-op
  end
end
