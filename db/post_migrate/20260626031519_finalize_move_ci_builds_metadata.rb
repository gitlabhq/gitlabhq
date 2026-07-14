# frozen_string_literal: true

class FinalizeMoveCiBuildsMetadata < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  restrict_gitlab_migration gitlab_schema: :gitlab_ci
  disable_ddl_transaction!

  # On GitLab.com the migration was enqueued per physical partition of
  # `p_ci_builds` and further split into several "view" sub-migrations. To
  # finalize all of them regardless of how they were enqueued, we look up the
  # persisted `BatchedMigration` records for the job class and finalize each one
  # using its own stored configuration.
  MIGRATION = 'MoveCiBuildsMetadata'

  def up
    return unless Gitlab.com_except_jh?

    finalize_configurations_for(MIGRATION) do |config|
      ensure_batched_background_migration_is_finished(
        **config.slice(
          :job_class_name,
          :table_name,
          :column_name,
          :job_arguments
        ).symbolize_keys
      )
    end
  end

  def down
    # no-op: finalizing a batched background migration is not reversible.
  end

  private

  def finalize_configurations_for(job_class_name)
    Gitlab::Database::BackgroundMigration::BatchedMigration
      .where(job_class_name: job_class_name)
      .find_each { |migration| yield(migration) }
  end
end
