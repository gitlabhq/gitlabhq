class ScheduleToArchiveLegacyTraces < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 5000
  BACKGROUND_MIGRATION_CLASS = 'ArchiveLegacyTraces'

  disable_ddl_transaction!

  class Build < ActiveRecord::Base
    include EachBatch
    self.table_name = 'ci_builds'
    self.inheritance_column = :_type_disabled # Disable STI

    scope :type_build, -> { where(type: 'Ci::Build') }

    scope :finished, -> { where(status: [:success, :failed, :canceled]) }

    scope :without_archived_trace, -> do
      where('NOT EXISTS (SELECT 1 FROM ci_job_artifacts WHERE ci_builds.id = ci_job_artifacts.job_id AND ci_job_artifacts.file_type = 3)')
    end
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      ::ScheduleToArchiveLegacyTraces::Build.type_build.finished.without_archived_trace,
      BACKGROUND_MIGRATION_CLASS,
      5.minutes,
      batch_size: BATCH_SIZE)
  end

  def down
    # noop
  end
end
