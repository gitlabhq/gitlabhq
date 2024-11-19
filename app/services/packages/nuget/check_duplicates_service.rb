# frozen_string_literal: true

module Packages
  module Nuget
    class CheckDuplicatesService < BaseService
      include Gitlab::Utils::StrongMemoize

      ExtractionError = Class.new(StandardError)

      def execute
        return ServiceResponse.success if Namespace::PackageSetting.duplicates_allowed?(existing_package)
        return ServiceResponse.success unless target_package_is_duplicate?

        ServiceResponse.error(
          message: 'A package with the same name and version already exists',
          reason: :conflict
        )
      rescue ExtractionError => e
        ServiceResponse.error(message: e.message, reason: :bad_request)
      end

      private

      def target_package_is_duplicate?
        existing_package.name.casecmp(metadata[:package_name]) == 0 &&
          (existing_package.version.casecmp(metadata[:package_version]) == 0 ||
            existing_package.normalized_nuget_version&.casecmp(metadata[:package_version]) == 0)
      end

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
        if params[:remote_url].present?
          ::Packages::Nuget::ExtractMetadataContentService
            .new(nuspec_file_content)
            .execute
            .payload
        else # to cover the case when package file is on disk not in object storage
          Zip::InputStream.open(params[:file]) do |zip|
            ::Packages::Nuget::MetadataExtractionService
              .new(zip)
              .execute
              .payload
          end
        end
      end
      strong_memoize_attr :metadata

      def nuspec_file_content
        ::Packages::Nuget::ExtractRemoteMetadataFileService
          .new(params[:remote_url])
          .execute
          .payload
      rescue ::Packages::Nuget::ExtractRemoteMetadataFileService::ExtractionError => e
        raise ExtractionError, e.message
      end
    end
  end
end
