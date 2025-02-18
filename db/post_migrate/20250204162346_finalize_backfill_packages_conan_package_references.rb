# frozen_string_literal: true

class FinalizeBackfillPackagesConanPackageReferences < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '17.9'

  MIGRATION = 'BackfillPackagesConanPackageReferences'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :packages_conan_file_metadata,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
