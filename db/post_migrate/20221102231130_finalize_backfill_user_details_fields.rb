# frozen_string_literal: true

class FinalizeBackfillUserDetailsFields < Gitlab::Database::Migration[2.0]
  BACKFILL_MIGRATION = 'BackfillUserDetailsFields'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: BACKFILL_MIGRATION,
      table_name: :users,
      column_name: :id,
      job_arguments: [],
      finalize: true)
  end

  def down; end
end
