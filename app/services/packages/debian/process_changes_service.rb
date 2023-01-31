# frozen_string_literal: true

module Packages
  module Debian
    class ProcessChangesService
      include ExclusiveLeaseGuard
      include Gitlab::Utils::StrongMemoize

      # used by ExclusiveLeaseGuard
      DEFAULT_LEASE_TIMEOUT = 1.hour.to_i.freeze

      def initialize(package_file, creator)
        @package_file = package_file
        @creator = creator
      end

      def execute
        # return if changes file has already been processed
        return if package_file.debian_file_metadatum&.changes?

        validate!

        try_obtain_lease do
          package_file.transaction do
            update_files_metadata
            update_changes_metadata
          end

          ::Packages::Debian::GenerateDistributionWorker.perform_async(:project, package.debian_distribution.id)
        end
      end

      private

      attr_reader :package_file, :creator

      def validate!
        raise ArgumentError, 'invalid package file' unless package_file.debian_file_metadatum
        raise ArgumentError, 'invalid package file' unless package_file.debian_file_metadatum.unknown?
        raise ArgumentError, 'invalid package file' unless metadata[:file_type] == :changes
        raise ArgumentError, 'missing Source field' unless metadata.dig(:fields, 'Source').present?
        raise ArgumentError, 'missing Version field' unless metadata.dig(:fields, 'Version').present?
        raise ArgumentError, 'missing Distribution field' unless metadata.dig(:fields, 'Distribution').present?
      end

      def update_files_metadata
        files.each do |filename, entry|
          file_metadata = ::Packages::Debian::ExtractMetadataService.new(entry.package_file).execute

          ::Packages::UpdatePackageFileService.new(entry.package_file, package_id: package.id)
            .execute

          # Force reload from database, as package has changed
          entry.package_file.reload_package

          entry.package_file.debian_file_metadatum.update!(
            file_type: file_metadata[:file_type],
            component: files[filename].component,
            architecture: file_metadata[:architecture],
            fields: file_metadata[:fields]
          )
        end
      end

      def update_changes_metadata
        ::Packages::UpdatePackageFileService.new(package_file, package_id: package.id)
          .execute

        # Force reload from database, as package has changed
        package_file.reload_package

        package_file.debian_file_metadatum.update!(
          file_type: metadata[:file_type],
          fields: metadata[:fields]
        )
      end

      def metadata
        strong_memoize(:metadata) do
          ::Packages::Debian::ExtractChangesMetadataService.new(package_file).execute
        end
      end

      def files
        metadata[:files]
      end

      def project
        package_file.package.project
      end

      def package
        strong_memoize(:package) do
          params = {
            'name': metadata[:fields]['Source'],
            'version': metadata[:fields]['Version'],
            'distribution_name': metadata[:fields]['Distribution']
          }
          response = Packages::Debian::FindOrCreatePackageService.new(project, creator, params).execute
          response.payload[:package]
        end
      end

      # used by ExclusiveLeaseGuard
      def lease_key
        "packages:debian:process_changes_service:package_file:#{package_file.id}"
      end

      # used by ExclusiveLeaseGuard
      def lease_timeout
        DEFAULT_LEASE_TIMEOUT
      end
    end
  end
end
