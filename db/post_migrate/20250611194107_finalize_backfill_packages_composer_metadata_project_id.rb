# frozen_string_literal: true

class FinalizeBackfillPackagesComposerMetadataProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillPackagesComposerMetadataProjectId',
      table_name: :packages_composer_metadata,
      column_name: :package_id,
      job_arguments: [:project_id, :packages_packages, :project_id, :package_id],
      finalize: true
    )
  end

  def down; end
end
