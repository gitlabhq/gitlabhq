# frozen_string_literal: true

class FinalizeBackfillRolledUpWeightForWorkItems < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  disable_ddl_transaction!

  MIGRATION = "BackfillRolledUpWeightForWorkItems"

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :issues,
      column_name: :id,
      job_arguments: []
    )
  end

  def down
    # no-op - finalization migrations are irreversible
  end
end
