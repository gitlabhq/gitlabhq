# frozen_string_literal: true

class FinalizeHkFixUsernamespaceAuditEvents < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'FixUsernamespaceAuditEvents',
      table_name: :audit_events,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
