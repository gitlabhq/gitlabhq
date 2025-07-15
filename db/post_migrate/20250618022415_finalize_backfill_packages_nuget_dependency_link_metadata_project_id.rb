# frozen_string_literal: true

class FinalizeBackfillPackagesNugetDependencyLinkMetadataProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillPackagesNugetDependencyLinkMetadataProjectId',
      table_name: :packages_nuget_dependency_link_metadata,
      column_name: :dependency_link_id,
      job_arguments: [:project_id, :packages_dependency_links, :project_id, :dependency_link_id],
      finalize: true
    )
  end

  def down; end
end
