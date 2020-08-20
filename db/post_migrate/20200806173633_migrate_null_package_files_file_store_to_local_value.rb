# frozen_string_literal: true

class MigrateNullPackageFilesFileStoreToLocalValue < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  JOB_INTERVAL = 2.minutes + 5.seconds
  BATCH_SIZE = 5_000
  MIGRATION = 'SetNullPackageFilesFileStoreToLocalValue'

  disable_ddl_transaction!

  class PackageFile < ActiveRecord::Base
    self.table_name = 'packages_package_files'

    include ::EachBatch
  end

  def up
    # On GitLab.com, there are 2M package files. None have NULL file_store
    # because they are all object stored. This is a no-op for GitLab.com.
    #
    # If a customer had 2M package files with NULL file_store, with batches of
    # 5000 and a background migration job interval of 2m 5s, then 400 jobs would
    # be scheduled over 14 hours.
    #
    # The index `index_packages_package_files_file_store_is_null` is
    # expected to be used here and in the jobs.
    #
    # queue_background_migration_jobs_by_range_at_intervals is not used because
    # it would enqueue 18.6K jobs and we have an index for getting these ranges.
    PackageFile.where(file_store: nil).each_batch(of: BATCH_SIZE) do |batch, index|
      range = batch.pluck(Arel.sql("MIN(id)"), Arel.sql("MAX(id)")).first
      delay = index * JOB_INTERVAL

      migrate_in(delay.seconds, MIGRATION, [*range])
    end
  end

  def down
    # noop
  end
end
