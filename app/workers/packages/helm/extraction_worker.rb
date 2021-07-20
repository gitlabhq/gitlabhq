# frozen_string_literal: true

module Packages
  module Helm
    class ExtractionWorker
      include ApplicationWorker

      queue_namespace :package_repositories
      feature_category :package_registry
      deduplicate :until_executing

      idempotent!

      def perform(channel, package_file_id)
        package_file = ::Packages::PackageFile.find_by_id(package_file_id)

        return unless package_file && !package_file.package.default?

        ::Packages::Helm::ProcessFileService.new(channel, package_file).execute

      rescue ::Packages::Helm::ExtractFileMetadataService::ExtractionError,
             ::Packages::Helm::ProcessFileService::ExtractionError,
             ::ActiveModel::ValidationError => e
        Gitlab::ErrorTracking.log_exception(e, project_id: package_file.project_id)
        package_file.package.update_column(:status, :error)
      end
    end
  end
end
