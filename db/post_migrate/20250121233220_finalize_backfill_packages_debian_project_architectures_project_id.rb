# frozen_string_literal: true

class FinalizeBackfillPackagesDebianProjectArchitecturesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillPackagesDebianProjectArchitecturesProjectId',
      table_name: :packages_debian_project_architectures,
      column_name: :id,
      job_arguments: [:project_id, :packages_debian_project_distributions, :project_id, :distribution_id],
      finalize: true
    )
  end

  def down; end
end
