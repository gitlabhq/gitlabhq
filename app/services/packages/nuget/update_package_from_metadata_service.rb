# frozen_string_literal: true

module Packages
  module Nuget
    class UpdatePackageFromMetadataService
      include Gitlab::Utils::StrongMemoize
      include ExclusiveLeaseGuard

      # used by ExclusiveLeaseGuard
      DEFAULT_LEASE_TIMEOUT = 1.hour.to_i.freeze
      SYMBOL_PACKAGE_IDENTIFIER = 'SymbolsPackage'
      INVALID_METADATA_ERROR_MESSAGE = 'package name, version, authors and/or description not found in metadata'
      INVALID_METADATA_ERROR_SYMBOL_MESSAGE = 'package name, version and/or description not found in metadata'
      MISSING_MATCHING_PACKAGE_ERROR_MESSAGE = 'symbol package is invalid, matching package does not exist'

      InvalidMetadataError = Class.new(StandardError)
      ZipError = Class.new(StandardError)

      def initialize(package_file)
        @package_file = package_file
      end

      def execute
        unless valid_metadata?
          error_message = symbol_package? ? INVALID_METADATA_ERROR_SYMBOL_MESSAGE : INVALID_METADATA_ERROR_MESSAGE
          raise InvalidMetadataError, error_message
        end

        try_obtain_lease do
          @package_file.transaction do
            process_package_update
          end
        end
      rescue ActiveRecord::RecordInvalid => e
        raise InvalidMetadataError, e.message
      rescue Zip::Error
        raise ZipError, 'Could not open the .nupkg file'
      end

      private

      def process_package_update
        package_to_destroy = nil
        target_package = @package_file.package

        if existing_package
          package_to_destroy = @package_file.package
          target_package = existing_package
        else
          if symbol_package?
            raise InvalidMetadataError, MISSING_MATCHING_PACKAGE_ERROR_MESSAGE
          end

          update_linked_package
        end

        update_package(target_package)
        ::Packages::UpdatePackageFileService.new(@package_file, package_id: target_package.id, file_name: package_filename)
                                            .execute
        package_to_destroy&.destroy!
      end

      def update_package(package)
        return if symbol_package?

        ::Packages::Nuget::SyncMetadatumService
          .new(package, metadata.slice(:authors, :description, :project_url, :license_url, :icon_url))
          .execute

        ::Packages::UpdateTagsService
          .new(package, package_tags)
          .execute

      rescue StandardError => e
        raise InvalidMetadataError, e.message
      end

      def valid_metadata?
        fields = [package_name, package_version, package_description]
        fields << package_authors unless symbol_package?
        fields.all?(&:present?)
      end

      def link_to_existing_package
        package_to_destroy = @package_file.package
        # Updating package_id updates the path where the file is stored.
        # We must pass the file again so that CarrierWave can handle the update
        @package_file.update!(
          package_id: existing_package.id,
          file: @package_file.file
        )
        package_to_destroy.destroy!
        existing_package
      end

      def update_linked_package
        @package_file.package.update!(
          name: package_name,
          version: package_version,
          status: :default
        )

        ::Packages::Nuget::CreateDependencyService.new(@package_file.package, package_dependencies)
                                                  .execute
        @package_file.package
      end

      def existing_package
        @package_file.project.packages
                             .nuget
                             .with_name(package_name)
                             .with_version(package_version)
                             .not_pending_destruction
                             .first
      end
      strong_memoize_attr :existing_package

      def package_name
        metadata[:package_name]
      end

      def package_version
        metadata[:package_version]
      end

      def package_dependencies
        metadata.fetch(:package_dependencies, [])
      end

      def package_tags
        metadata.fetch(:package_tags, [])
      end

      def package_types
        metadata.fetch(:package_types, [])
      end

      def package_authors
        metadata[:authors]
      end

      def package_description
        metadata[:description]
      end

      def symbol_package?
        package_types.include?(SYMBOL_PACKAGE_IDENTIFIER)
      end

      def metadata
        ::Packages::Nuget::MetadataExtractionService.new(@package_file).execute.payload
      end
      strong_memoize_attr :metadata

      def package_filename
        "#{package_name.downcase}.#{package_version.downcase}.#{symbol_package? ? 'snupkg' : 'nupkg'}"
      end

      # used by ExclusiveLeaseGuard
      def lease_key
        package_id = existing_package ? existing_package.id : @package_file.package_id
        "packages:nuget:update_package_from_metadata_service:package:#{package_id}"
      end

      # used by ExclusiveLeaseGuard
      def lease_timeout
        DEFAULT_LEASE_TIMEOUT
      end
    end
  end
end
