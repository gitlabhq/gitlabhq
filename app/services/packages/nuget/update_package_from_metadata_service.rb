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

      InvalidMetadataError = ZipError = DuplicatePackageError = Class.new(StandardError)

      def initialize(package_file, package_zip_file)
        @package_file = package_file
        @package_zip_file = package_zip_file
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

        create_symbol_files
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
          raise DuplicatePackageError, "A package '#{package_name}' with version '#{package_version}' already exists" unless symbol_package? || duplicates_allowed?

          package_to_destroy = @package_file.package
          target_package = existing_package
        else
          if symbol_package?
            raise InvalidMetadataError, MISSING_MATCHING_PACKAGE_ERROR_MESSAGE
          end

          update_linked_package
        end

        build_infos = package_to_destroy&.build_infos || []

        update_package(target_package, build_infos)
        ::Packages::UpdatePackageFileService.new(@package_file, package_id: target_package.id, file_name: package_filename)
                                            .execute
        package_to_destroy&.destroy!
      end

      def duplicates_allowed?
        ::Namespace::PackageSetting.duplicates_allowed?(existing_package)
      end

      def update_package(package, build_infos)
        return if symbol_package?

        ::Packages::Nuget::SyncMetadatumService
          .new(package, metadata.slice(:authors, :description, :project_url, :license_url, :icon_url))
          .execute

        ::Packages::UpdateTagsService
          .new(package, package_tags)
          .execute

        package.build_infos << build_infos if build_infos.any?
      rescue StandardError => e
        raise InvalidMetadataError, e.message
      end

      def create_symbol_files
        return unless symbol_package?

        ::Packages::Nuget::Symbols::CreateSymbolFilesService
          .new(existing_package, @package_zip_file)
          .execute
      end

      def valid_metadata?
        fields = [package_name, package_version, package_description]
        fields << package_authors unless symbol_package?
        fields.all?(&:present?)
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
        ::Packages::Nuget::PackageFinder
          .new(
            nil,
            @package_file.project,
            package_name: package_name,
            package_version: package_version
          )
          .execute
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
      strong_memoize_attr :symbol_package?

      def metadata
        ::Packages::Nuget::MetadataExtractionService.new(@package_zip_file).execute.payload
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
