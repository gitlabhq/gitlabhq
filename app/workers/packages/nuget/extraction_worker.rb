# frozen_string_literal: true

module Packages
  module Nuget
    class ExtractionWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker

      sidekiq_options retry: 3

      queue_namespace :package_repositories
      feature_category :package_registry

      def perform(package_file_id)
        package_file = ::Packages::PackageFile.find_by_id(package_file_id)

        return unless package_file

        ::Packages::Nuget::UpdatePackageFromMetadataService.new(package_file).execute

      rescue StandardError => e
        Gitlab::ErrorTracking.log_exception(e, project_id: package_file.project_id)
        package_file.package.update_column(:status, :error)
      end
    end
  end
end
