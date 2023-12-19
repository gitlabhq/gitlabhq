# frozen_string_literal: true

class FinalizeMarkDuplicateNpmPackagesForDestruction < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'MarkDuplicateNpmPackagesForDestruction',
      table_name: :packages_packages,
      column_name: :project_id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
