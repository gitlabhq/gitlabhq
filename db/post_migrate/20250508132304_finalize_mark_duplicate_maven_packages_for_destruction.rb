# frozen_string_literal: true

class FinalizeMarkDuplicateMavenPackagesForDestruction < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '18.0'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'MarkDuplicateMavenPackagesForDestruction',
      table_name: :packages_packages,
      column_name: :project_id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
