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
    # TODO: Consider when unique constraint violation of job_artifacts (i.e. duplicates inserts)
    scope :legacy_artifacts, -> do
      where('artifacts_file IS NOT NULL AND artifacts_file <> ?', '')
    end
  end

  def up
    disable_statement_timeout

    MigrateLegacyArtifactsToJobArtifacts::Build.legacy_artifacts.tap do |relation|
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
