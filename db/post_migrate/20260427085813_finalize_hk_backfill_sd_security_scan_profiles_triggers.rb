# frozen_string_literal: true

class FinalizeHkBackfillSdSecurityScanProfilesTriggers < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillSdSecurityScanProfilesTriggers',
      table_name: :security_scan_profiles,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
