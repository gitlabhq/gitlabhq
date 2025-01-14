# frozen_string_literal: true

module Packages
  module Nuget
    class CheckDuplicatesService < BaseService
      include Gitlab::Utils::StrongMemoize

      ExtractionError = Class.new(StandardError)

      def execute
        return ServiceResponse.success if package_settings_allow_duplicates?

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
        response = ::Packages::Nuget::ExtractRemoteMetadataFileService
          .new(params[:remote_url])
          .execute

        raise ExtractionError, response.message if response.error?

        response.payload
      end
    end
  end
end
