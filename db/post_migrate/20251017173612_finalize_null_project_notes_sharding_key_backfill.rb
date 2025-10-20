# frozen_string_literal: true

class FinalizeNullProjectNotesShardingKeyBackfill < Gitlab::Database::Migration[2.3]
  MIGRATION = 'BackfillMissingNamespaceIdOnNotes'

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  milestone '18.6'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :notes,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
