# frozen_string_literal: true

module Packages
  module Nuget
    class CheckDuplicatesService < BaseService
      include Gitlab::Utils::StrongMemoize

      ExtractionError = Class.new(StandardError)

      def execute
        return ServiceResponse.success if package_settings_allow_duplicates? || !target_package_is_duplicate?

        ServiceResponse.error(
          message: 'A package with the same name and version already exists',
          reason: :conflict
        )
      rescue ExtractionError => e
        ServiceResponse.error(message: e.message, reason: :bad_request)
      end

      private

      def package_settings_allow_duplicates?
        package_settings.nuget_duplicates_allowed? || package_settings.class.duplicates_allowed?(existing_package)
      end

      def target_package_is_duplicate?
        existing_package.name.casecmp(metadata[:package_name]) == 0 &&
          (existing_package.version.casecmp(metadata[:package_version]) == 0 ||
            existing_package.normalized_nuget_version&.casecmp(metadata[:package_version]) == 0)
      end

      def package_settings
        project.namespace.package_settings
      end
      strong_memoize_attr :package_settings

      def existing_package
        ::Packages::Nuget::PackageFinder
          .new(
            current_user,
            project,
            package_name: metadata[:package_name],
            package_version: metadata[:package_version]
          )
          .execute
          .first
      end
      strong_memoize_attr :existing_package

      def metadata
        if remote_package_file?
          ExtractMetadataContentService
            .new(nuspec_file_content)
            .execute
            .payload
        else # to cover the case when package file is on disk not in object storage
          MetadataExtractionService
            .new(mock_package_file)
            .execute
            .payload
        end
      end
      strong_memoize_attr :metadata

      def remote_package_file?
        params[:remote_url].present?
      end

      def nuspec_file_content
        ExtractRemoteMetadataFileService
          .new(params[:remote_url])
          .execute
          .payload
      rescue ExtractRemoteMetadataFileService::ExtractionError => e
        raise ExtractionError, e.message
      end

      def mock_package_file
        ::Packages::PackageFile.new(
          params
            .slice(:file, :file_name)
            .merge(package: ::Packages::Package.nuget.build)
        )
      end
    end
  end
end
