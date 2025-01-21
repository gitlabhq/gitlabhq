# frozen_string_literal: true

class FinalizeBackfillPackagesNugetSymbolsProjectId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.9'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillPackagesNugetSymbolsProjectId',
      table_name: :packages_nuget_symbols,
      column_name: :id,
      job_arguments: [
        :project_id,
        :packages_packages,
        :project_id,
        :package_id
      ],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
