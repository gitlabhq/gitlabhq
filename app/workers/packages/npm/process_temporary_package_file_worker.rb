# frozen_string_literal: true

module Packages
  module Npm
    class ProcessTemporaryPackageFileWorker
      include ApplicationWorker
      include ::Packages::ErrorHandling

      data_consistency :sticky
      queue_namespace :package_repositories
      feature_category :package_registry
      deduplicate :until_executed
      idempotent!

      def perform(user_id, package_file_id, deprecate)
        user = User.find_by_id(user_id)
        return unless user

        package_file = ::Packages::PackageFile.processing.find_by_id(package_file_id)
        return unless package_file

        params = { deprecate: }

        response = ::Packages::Npm::ProcessTemporaryPackageFileService.new(package_file:, user:, params:).execute
        process_package_error_service_response(package_file: package_file, message: response.message) if response.error?
      rescue StandardError => exception
        raise exception unless package_file

        process_package_file_error(package_file: package_file, exception: exception)
      end
    end
  end
end
