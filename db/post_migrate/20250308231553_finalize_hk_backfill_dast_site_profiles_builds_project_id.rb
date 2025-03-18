# frozen_string_literal: true

class FinalizeHkBackfillDastSiteProfilesBuildsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillDastSiteProfilesBuildsProjectId',
      table_name: :dast_site_profiles_builds,
      column_name: :ci_build_id,
      job_arguments: [:project_id, :dast_site_profiles, :project_id, :dast_site_profile_id],
      finalize: true
    )
  end

  def down; end
end
