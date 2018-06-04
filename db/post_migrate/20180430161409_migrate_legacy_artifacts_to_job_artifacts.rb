class MigrateLegacyArtifactsToJobArtifacts < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION = 'MigrateLegacyArtifacts'.freeze
  BATCH_SIZE = 2000

  disable_ddl_transaction!

  class Build < ActiveRecord::Base
    include EachBatch
    self.table_name = 'ci_builds'
    self.inheritance_column = :_type_disabled # disable STI

    scope :legacy_artifacts, -> { where("artifacts_file <> ''") }

    scope :without_new_artifacts, -> do
      where('NOT EXISTS (?)', MigrateLegacyArtifactsToJobArtifacts::JobArtifact.select(1).where('ci_builds.id = ci_job_artifacts.job_id').archive)
    end
  end

  class JobArtifact < ActiveRecord::Base
    self.table_name = 'ci_job_artifacts'

    enum file_type: {
      archive: 1,
      metadata: 2,
      trace: 3
    }
  end

  def up
    MigrateLegacyArtifactsToJobArtifacts::Build.legacy_artifacts.without_new_artifacts.tap do |relation|
      queue_background_migration_jobs_by_range_at_intervals(relation,
                                                            MIGRATION,
                                                            5.minutes,
                                                            batch_size: BATCH_SIZE)
    end
  end

  def down
    # no-op
  end
end
