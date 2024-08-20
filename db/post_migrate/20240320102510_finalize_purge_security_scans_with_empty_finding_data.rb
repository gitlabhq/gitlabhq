# frozen_string_literal: true

class FinalizePurgeSecurityScansWithEmptyFindingData < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.11'
  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  def up
    return if Gitlab.com? || !Gitlab.ee?

    ensure_batched_background_migration_is_finished(
      job_class_name: 'PurgeSecurityScansWithEmptyFindingData',
      table_name: :security_scans,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
