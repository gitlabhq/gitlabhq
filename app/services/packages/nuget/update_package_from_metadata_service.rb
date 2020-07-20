# frozen_string_literal: true

module Packages
  module Nuget
    class UpdatePackageFromMetadataService
      include Gitlab::Utils::StrongMemoize
      include ExclusiveLeaseGuard

      # used by ExclusiveLeaseGuard
      DEFAULT_LEASE_TIMEOUT = 1.hour.to_i.freeze

      InvalidMetadataError = Class.new(StandardError)

      def initialize(package_file)
        @package_file = package_file
      end

      def execute
        raise InvalidMetadataError.new('package name and/or package version not found in metadata') unless valid_metadata?

        try_obtain_lease do
          @package_file.transaction do
            package = existing_package ? link_to_existing_package : update_linked_package

            update_package(package)

            # Updating file_name updates the path where the file is stored.
            # We must pass the file again so that CarrierWave can handle the update
            @package_file.update!(
              file_name: package_filename,
              file: @package_file.file
            )
          end
        end
      end

      private

      def update_package(package)
        ::Packages::Nuget::SyncMetadatumService
          .new(package, metadata.slice(:project_url, :license_url, :icon_url))
          .execute
        ::Packages::UpdateTagsService
          .new(package, package_tags)
          .execute
      rescue => e
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
          version: package_version
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

      def metadata
        strong_memoize(:metadata) do
          ::Packages::Nuget::MetadataExtractionService.new(@package_file.id).execute
        end
      end

      def package_filename
        "#{package_name.downcase}.#{package_version.downcase}.nupkg"
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
