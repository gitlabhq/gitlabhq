# frozen_string_literal: true

class FinalizeHkBackfillNewAuditEventTables < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillNewAuditEventTables',
      table_name: :audit_events,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
