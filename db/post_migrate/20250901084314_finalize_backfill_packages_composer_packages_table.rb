# frozen_string_literal: true

class FinalizeBackfillPackagesComposerPackagesTable < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  milestone '18.4'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillPackagesComposerPackagesTable',
      table_name: :packages_packages,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
