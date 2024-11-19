# frozen_string_literal: true

class FinalizeBackfillDastScannerProfilesBuildsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillDastScannerProfilesBuildsProjectId',
      table_name: :dast_scanner_profiles_builds,
      column_name: :ci_build_id,
      job_arguments: [:project_id, :dast_scanner_profiles, :project_id, :dast_scanner_profile_id],
      finalize: true
    )
  end

  def down; end
end
