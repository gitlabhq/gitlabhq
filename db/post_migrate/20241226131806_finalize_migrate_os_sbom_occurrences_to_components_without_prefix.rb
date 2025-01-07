# frozen_string_literal: true

class FinalizeMigrateOsSbomOccurrencesToComponentsWithoutPrefix < Gitlab::Database::Migration[2.2]
  milestone '17.8'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'MigrateOsSbomOccurrencesToComponentsWithoutPrefix',
      table_name: :sbom_components,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
