# frozen_string_literal: true

class RemoveBackfillRolledUpWeightForWorkItems < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillRolledUpWeightForWorkItems"

  def up
    delete_batched_background_migration(MIGRATION, :issues, :id, [])
  end

  def down
    # no-op
  end
end
