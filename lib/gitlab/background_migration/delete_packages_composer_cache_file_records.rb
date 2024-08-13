# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class DeletePackagesComposerCacheFileRecords < BatchedMigrationJob
      extend ::Gitlab::Utils::Override

      operation_name :destroy_all
      feature_category :package_registry

      module Packages
        module Composer
          class CacheFile < ApplicationRecord
            include EachBatch
            include FileStoreMounter

            self.table_name = 'packages_composer_cache_files'

            mount_file_store_uploader ::Packages::Composer::CacheUploader
          end
        end
      end

      def perform
        each_sub_batch(&:destroy_all)
      end

      override :base_relation
      def base_relation
        Packages::Composer::CacheFile
      end
    end
  end
end
