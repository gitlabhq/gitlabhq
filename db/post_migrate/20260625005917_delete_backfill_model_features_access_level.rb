# frozen_string_literal: true

# Stops and removes the BackfillModelFeaturesAccessLevel batched background
# migration that was enqueued by 20260617140000 (now a no-op), as part of
# reverting !241182. See the incident and !242424. The backfill will be
# resubmitted separately once the feature is reintroduced.
class DeleteBackfillModelFeaturesAccessLevel < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillModelFeaturesAccessLevel"

  def up
    delete_batched_background_migration(MIGRATION, :project_features, :id, [])
  end

  def down
    # no-op: the backfill is being reverted and will be resubmitted separately.
  end
end
