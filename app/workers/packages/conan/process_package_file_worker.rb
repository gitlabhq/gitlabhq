# frozen_string_literal: true

module Packages
  module Conan
    class ProcessPackageFileWorker
      include ApplicationWorker

      data_consistency :sticky
      queue_namespace :package_repositories
      feature_category :package_registry
      deduplicate :until_executed
      idempotent!

      def perform(package_file_id)
        package_file = ::Packages::PackageFile.find_by_id(package_file_id)
        return unless package_file

        ::Packages::Conan::MetadataExtractionService.new(package_file).execute
      rescue StandardError => exception
        logger.warn(
          message: "Error processing conaninfo.txt file",
          error: exception.message,
          package_file: package_file.id,
          project_id: package_file.project_id,
          package_name: package_file.package.name,
          package_version: package_file.package.version
        )
      end
    end
  end
end
