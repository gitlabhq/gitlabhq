# frozen_string_literal: true

class RemoveBackfillPCiPipelinesTriggerId < Gitlab::Database::Migration[2.2]
  milestone '17.8'
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  TABLE = :ci_trigger_requests
  PRIMARY_KEY = :id
  MIGRATION = "BackfillPCiPipelinesTriggerId"

  def up
    # Clear previous background migration execution from QueueBackfillPCiPipelinesTriggerId
    delete_batched_background_migration(
      MIGRATION, TABLE, PRIMARY_KEY, []
    )
  end

  def down
    # no-op
  end
end
