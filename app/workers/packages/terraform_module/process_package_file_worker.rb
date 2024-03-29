# frozen_string_literal: true

module Packages
  module TerraformModule
    class ProcessPackageFileWorker
      include ApplicationWorker

      data_consistency :sticky

      queue_namespace :package_repositories
      feature_category :package_registry
      deduplicate :until_executed
      urgency :low
      idempotent!

      def perform(package_file_id)
        package_file = ::Packages::PackageFile.find_by_id(package_file_id)

        return unless package_file

        ::Packages::TerraformModule::ProcessPackageFileService.new(package_file).execute
      rescue StandardError => e
        Gitlab::ErrorTracking.track_exception(
          e,
          package_id: package_file&.package_id
        )
      end
    end
  end
end
