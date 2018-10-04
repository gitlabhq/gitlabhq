class FillFileStore < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class JobArtifact < ActiveRecord::Base
    include EachBatch
    self.table_name = 'ci_job_artifacts'
    BATCH_SIZE = 10_000

    def self.params_for_background_migration
      yield self.where(file_store: nil), 'FillFileStoreJobArtifact', 5.minutes, BATCH_SIZE
    end
  end

  class LfsObject < ActiveRecord::Base
    include EachBatch
    self.table_name = 'lfs_objects'
    BATCH_SIZE = 10_000

    def self.params_for_background_migration
      yield self.where(file_store: nil), 'FillFileStoreLfsObject', 5.minutes, BATCH_SIZE
    end
  end

  class Upload < ActiveRecord::Base
    include EachBatch
    self.table_name = 'uploads'
    self.inheritance_column = :_type_disabled # Disable STI
    BATCH_SIZE = 10_000

    def self.params_for_background_migration
      yield self.where(store: nil), 'FillStoreUpload', 5.minutes, BATCH_SIZE
    end
  end

  def up
    # NOTE: Schedule background migrations that fill 'NULL' value by '1'(ObjectStorage::Store::LOCAL) on `file_store`, `store` columns
    #
    # Here are the target columns
    # - ci_job_artifacts.file_store
    # - lfs_objects.file_store
    # - uploads.store

    FillFileStore::JobArtifact.params_for_background_migration do |relation, class_name, delay_interval, batch_size|
      queue_background_migration_jobs_by_range_at_intervals(relation,
        class_name,
        delay_interval,
        batch_size: batch_size)
    end

    FillFileStore::LfsObject.params_for_background_migration do |relation, class_name, delay_interval, batch_size|
      queue_background_migration_jobs_by_range_at_intervals(relation,
        class_name,
        delay_interval,
        batch_size: batch_size)
    end

    FillFileStore::Upload.params_for_background_migration do |relation, class_name, delay_interval, batch_size|
      queue_background_migration_jobs_by_range_at_intervals(relation,
        class_name,
        delay_interval,
        batch_size: batch_size)
    end
  end

  def down
    # noop
  end
end
