# frozen_string_literal: true

module Packages
  module Helm
    class ExtractionWorker
      include ApplicationWorker
      include ::Packages::ErrorHandling

      data_consistency :always

      queue_namespace :package_repositories
      feature_category :package_registry
      deduplicate :until_executing

      idempotent!

      def perform(channel, package_file_id)
        package_file = ::Packages::PackageFile.find_by_id(package_file_id)

        return unless package_file && !package_file.package.default?

        ::Packages::Helm::ProcessFileService.new(channel, package_file).execute
      rescue StandardError => exception
        process_package_file_error(
          package_file: package_file,
          exception: exception
        )
      end
    end
  end
end
