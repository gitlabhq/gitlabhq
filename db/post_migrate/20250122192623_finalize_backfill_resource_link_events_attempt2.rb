# frozen_string_literal: true

class FinalizeBackfillResourceLinkEventsAttempt2 < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  milestone '17.9'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillResourceLinkEvents',
      table_name: :system_note_metadata,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
