class FillFileStore < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class Build < ActiveRecord::Base
    include EachBatch
    self.table_name = 'ci_builds'
    BATCH_SIZE = 10_000

    def self.queue_background_migration
      self.class.where(artifacts_file_store: nil).tap do |relation|
        queue_background_migration_jobs_by_range_at_intervals(relation,
          'FillFileStoreBuildArchive',
          5.minutes,
          batch_size: BATCH_SIZE)
      end

      self.class.where(artifacts_metadata_store: nil).tap do |relation|
        queue_background_migration_jobs_by_range_at_intervals(relation,
          'FillFileStoreBuildMetadata',
          5.minutes,
          batch_size: BATCH_SIZE)
      end
    end
  end

  class JobArtifact < ActiveRecord::Base
    include EachBatch
    self.table_name = 'ci_job_artifacts'
    BATCH_SIZE = 10_000

    def self.queue_background_migration
      self.class.where(file_store: nil).tap do |relation|
        queue_background_migration_jobs_by_range_at_intervals(relation,
          'FillFileStoreJobArtifact',
          5.minutes,
          batch_size: BATCH_SIZE)
      end
    end
  end

  class LfsObject < ActiveRecord::Base
    include EachBatch
    self.table_name = 'lfs_objects'
    BATCH_SIZE = 10_000

    def self.queue_background_migration
      self.class.where(file_store: nil).tap do |relation|
        queue_background_migration_jobs_by_range_at_intervals(relation,
          'FillFileStoreLfsObject',
          5.minutes,
          batch_size: BATCH_SIZE)
      end
    end
  end

  class Upload < ActiveRecord::Base
    include EachBatch
    self.table_name = 'uploads'
    BATCH_SIZE = 10_000

    def self.queue_background_migration
      self.class.where(store: nil).tap do |relation|
        queue_background_migration_jobs_by_range_at_intervals(relation,
          'FillFileStoreUpload',
          5.minutes,
          batch_size: BATCH_SIZE)
      end
    end
  end

  def up
    disable_statement_timeout

    # Schedule background migrations that fill 'NULL' value by '1' on `file_store`, `store`, `artifacts_file_store` columns
    # '1' represents ObjectStorage::Store::LOCAL
    # ci_builds.artifacts_file_store
    # ci_builds.artifacts_metadata_store
    # ci_job_artifacts.file_store
    # lfs_objects.file_store
    # uploads.store

    FillFileStore::Build.queue_background_migration
    FillFileStore::JobArtifact.queue_background_migration
    FillFileStore::LfsObject.queue_background_migration
    FillFileStore::Upload.queue_background_migration
  end

  def down
    # noop
  end
end
