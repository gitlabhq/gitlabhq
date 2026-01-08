# frozen_string_literal: true

class RequeueBackfillOfSecurityProjectTrackedContexts < Gitlab::Database::Migration[2.3]
  milestone '18.8'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillSecurityProjectTrackedContextsDefaultBranch"

  def up
    queue_batched_background_migration(
      MIGRATION,
      :project_settings,
      :project_id
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :project_settings, :project_id, [])
  end
end
