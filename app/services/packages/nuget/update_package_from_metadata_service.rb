# frozen_string_literal: true

module Packages
  module Nuget
    class UpdatePackageFromMetadataService
      include Gitlab::Utils::StrongMemoize
      include ExclusiveLeaseGuard

      # used by ExclusiveLeaseGuard
      DEFAULT_LEASE_TIMEOUT = 1.hour.to_i.freeze
      SYMBOL_PACKAGE_IDENTIFIER = 'SymbolsPackage'

      InvalidMetadataError = Class.new(StandardError)

      def initialize(package_file)
        @package_file = package_file
      end

      def execute
        raise InvalidMetadataError, 'package name and/or package version not found in metadata' unless valid_metadata?

        try_obtain_lease do
          @package_file.transaction do
            if existing_package
              package = link_to_existing_package
            elsif symbol_package?
              raise InvalidMetadataError, 'symbol package is invalid, matching package does not exist'
            else
              package = update_linked_package
            end

            update_package(package)

            # Updating file_name updates the path where the file is stored.
            # We must pass the file again so that CarrierWave can handle the update
            @package_file.update!(
              file_name: package_filename,
              file: @package_file.file
            )
          end
        end
      rescue ActiveRecord::RecordInvalid => e
        raise InvalidMetadataError, e.message
      end

      private

      def update_package(package)
        return if symbol_package?

        ::Packages::Nuget::SyncMetadatumService
          .new(package, metadata.slice(:project_url, :license_url, :icon_url))
          .execute
        ::Packages::UpdateTagsService
          .new(package, package_tags)
          .execute
      rescue StandardError => e
        raise InvalidMetadataError, e.message
      end

      def valid_metadata?
        package_name.present? && package_version.present?
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
        strong_memoize(:existing_package) do
          @package_file.project.packages
                               .nuget
                               .with_name(package_name)
                               .with_version(package_version)
                               .first
        end
      end

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

      def symbol_package?
        package_types.include?(SYMBOL_PACKAGE_IDENTIFIER)
      end

      def metadata
        strong_memoize(:metadata) do
          ::Packages::Nuget::MetadataExtractionService.new(@package_file.id).execute
        end
      end

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
