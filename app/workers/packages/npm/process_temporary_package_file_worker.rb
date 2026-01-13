# frozen_string_literal: true

module Packages
  module Npm
    class ProcessTemporaryPackageFileWorker
      include ApplicationWorker
      include ::Packages::ErrorHandling

      GLOBAL_ID_LOCATE_OPTIONS = { only: [::User, ::DeployToken] }.freeze

      data_consistency :sticky
      queue_namespace :package_repositories
      feature_category :package_registry
      deduplicate :until_executed
      idempotent!

      def perform(user_gid, package_file_id, deprecate)
        user = safe_locate(user_gid)
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

      private

      def safe_locate(gid)
        Gitlab::GlobalId.safe_locate(
          gid,
          on_error: ->(e) { Gitlab::ErrorTracking.track_exception(e, gid: gid, worker: self.class.name) },
          options: GLOBAL_ID_LOCATE_OPTIONS
        )
      end
    end
  end
end
