class MigrateLegacyArtifactsToJobArtifacts < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION = 'MigrateLegacyArtifacts'.freeze
  BATCH_SIZE = 2000
  TMP_INDEX = 'tmp_index_ci_builds_on_present_artifacts_file'.freeze

  disable_ddl_transaction!

  class Build < ActiveRecord::Base
    include EachBatch

    self.table_name = 'ci_builds'
    self.inheritance_column = :_type_disabled

    scope :with_legacy_artifacts, -> { where("artifacts_file <> ''") }

    scope :without_new_artifacts, -> do
      where('NOT EXISTS (SELECT 1 FROM ci_job_artifacts WHERE (ci_builds.id = ci_job_artifacts.job_id) AND ci_job_artifacts.file_type = 1)')
    end
  end

  def up
    ##
    # We add a temporary index to the `ci_builds.artifacts_file` column.
    # Without the index, the first query (`SELECT .. WHERE .. ORDER BY id ASC LIMIT 1``) of `each_batch` will likely fail by statement timeout.
    # The following querires which will be executed in backgroun migrartions are fine without the index,
    # because it's scanned by using `BETWEEN` clause (e.g. 'id BETWEEN 0 AND 2000') at the beginning and narrow down target rows.
    unless index_exists_by_name?(:ci_builds, TMP_INDEX)
      if Gitlab::Database.postgresql?
        add_concurrent_index :ci_builds, :artifacts_file, where: "artifacts_file <> ''", name: TMP_INDEX
      end
    end

    MigrateLegacyArtifactsToJobArtifacts::Build
      .with_legacy_artifacts.without_new_artifacts.tap do |relation|
      queue_background_migration_jobs_by_range_at_intervals(relation,
                                                            MIGRATION,
                                                            5.minutes,
                                                            batch_size: BATCH_SIZE)
    end

    remove_concurrent_index_by_name(:ci_builds, TMP_INDEX)
  end

  def down
    if index_exists_by_name?(:ci_builds, TMP_INDEX)
      remove_concurrent_index_by_name(:ci_builds, TMP_INDEX)
    end
  end
end
