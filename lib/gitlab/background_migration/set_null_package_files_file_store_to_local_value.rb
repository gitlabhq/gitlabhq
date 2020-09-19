# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This class is responsible for migrating a range of package files
    # with file_store == NULL to 1.
    #
    # The index `index_packages_package_files_file_store_is_null` is
    # expected to be used to find the rows here and in the migration scheduling
    # the jobs that run this class.
    class SetNullPackageFilesFileStoreToLocalValue
      LOCAL_STORE = 1 # equal to ObjectStorage::Store::LOCAL

      module Packages
        # Temporary AR class for package files
        class PackageFile < ActiveRecord::Base
          self.table_name = 'packages_package_files'
        end
      end

      def perform(start_id, stop_id)
        Packages::PackageFile.where(file_store: nil, id: start_id..stop_id).update_all(file_store: LOCAL_STORE)
      end
    end
  end
end
