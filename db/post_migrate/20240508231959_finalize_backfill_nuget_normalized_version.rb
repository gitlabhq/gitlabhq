# frozen_string_literal: true

class FinalizeBackfillNugetNormalizedVersion < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillNugetNormalizedVersion',
      table_name: :packages_nuget_metadata,
      column_name: :package_id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
