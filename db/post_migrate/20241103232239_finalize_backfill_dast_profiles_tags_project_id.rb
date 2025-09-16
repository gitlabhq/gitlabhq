# frozen_string_literal: true

class FinalizeBackfillDastProfilesTagsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillDastProfilesTagsProjectId',
      table_name: :dast_profiles_tags,
      column_name: :id,
      job_arguments: [:project_id, :dast_profiles, :project_id, :dast_profile_id],
      finalize: true
    )
  end

  def down; end
end
