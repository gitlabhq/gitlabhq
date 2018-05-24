class MigrateLegacyArtifactsToJobArtifacts < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION = 'MigrateLegacyArtifacts'.freeze
  BATCH_SIZE = 500

  disable_ddl_transaction!

  class Build < ActiveRecord::Base
    include EachBatch
    self.table_name = 'ci_builds'
    self.inheritance_column = :_type_disabled # disable STI

    ##
    # Jobs which have a value on `artifacts_file` column are targetted.
    # In addition, jobs which have already had job_artifacts are untargetted.
    # This usually doesn't happen, however, if it's the case, background migrations will be aborted
    scope :legacy_artifacts, -> do
      where('artifacts_file IS NOT NULL AND artifacts_file <> ?', '')
    end

    scope :without_new_artifacts, -> do
      where('NOT EXISTS (SELECT 1 FROM ci_job_artifacts WHERE ci_job_artifacts.id = ci_builds.id AND (file_type = 1 OR file_type = 2))')
    end
  end

  def up
    disable_statement_timeout

    MigrateLegacyArtifactsToJobArtifacts::Build.legacy_artifacts.without_new_artifacts.tap do |relation|
      queue_background_migration_jobs_by_range_at_intervals(relation,
                                                            MIGRATION,
                                                            5.minutes,
                                                            batch_size: BATCH_SIZE)
    end
  end

  def down
    # There's nothing to revert for this migration.
  end
end
