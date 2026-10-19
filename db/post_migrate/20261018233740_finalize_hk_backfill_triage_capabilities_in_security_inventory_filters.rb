# frozen_string_literal: true

class FinalizeHkBackfillTriageCapabilitiesInSecurityInventoryFilters < Gitlab::Database::Migration[2.4]
  milestone '19.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillTriageCapabilitiesInSecurityInventoryFilters',
      table_name: :security_scan_profiles_projects,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
