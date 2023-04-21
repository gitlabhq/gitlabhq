# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class FinalizeFixIncoherentPackagesSizeOnProjectStatistics < Gitlab::Database::Migration[2.1]
  MIGRATION = 'FixIncoherentPackagesSizeOnProjectStatistics'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :project_statistics,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
