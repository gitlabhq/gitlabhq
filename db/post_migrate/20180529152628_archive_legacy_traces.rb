class ArchiveLegacyTraces < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 10_000
  BACKGROUND_MIGRATION_CLASS = 'ArchiveLegacyTraces'

  disable_ddl_transaction!

  class Build < ActiveRecord::Base
    include EachBatch
    self.table_name = 'ci_builds'
    self.inheritance_column = :_type_disabled # Disable STI

    scope :finished, -> { where(status: [:success, :failed, :canceled]) }

    scope :without_new_traces, ->() do
      where('NOT EXISTS (?)',
        ::ArchiveLegacyTraces::JobArtifact.select(1).trace.where('ci_builds.id = ci_job_artifacts.job_id'))
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
    queue_background_migration_jobs_by_range_at_intervals(
      ::ArchiveLegacyTraces::Build.finished.without_new_traces,
      BACKGROUND_MIGRATION_CLASS,
      5.minutes,
      batch_size: BATCH_SIZE)
  end

  def down
    # noop
  end
end
