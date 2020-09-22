# frozen_string_literal: true

class EnsureFilledFileStoreOnPackageFiles < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  BACKGROUND_MIGRATION_CLASS = 'SetNullPackageFilesFileStoreToLocalValue'
  BATCH_SIZE = 5_000
  LOCAL_STORE = 1 # equal to ObjectStorage::Store::LOCAL
  DOWNTIME = false

  disable_ddl_transaction!

  module Packages
    class PackageFile < ActiveRecord::Base
      self.table_name = 'packages_package_files'

      include ::EachBatch
    end
  end

  def up
    Gitlab::BackgroundMigration.steal(BACKGROUND_MIGRATION_CLASS)

    # Do a manual update in case we lost BG jobs. The expected record count should be 0 or very low.
    Packages::PackageFile.where(file_store: nil).each_batch(of: BATCH_SIZE) do |batch, index|
      batch.update_all(file_store: LOCAL_STORE)
    end
  end

  def down
    # no-op
  end
end
