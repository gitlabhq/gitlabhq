# frozen_string_literal: true

class FinalizeHkBackfillPackagesNugetSymbolStatesProjectId < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillPackagesNugetSymbolStatesProjectId',
      table_name: :packages_nuget_symbol_states,
      column_name: :packages_nuget_symbol_id,
      job_arguments: [:project_id, :packages_nuget_symbols, :project_id, :packages_nuget_symbol_id],
      finalize: true
    )
  end

  def down; end
end
