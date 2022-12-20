# frozen_string_literal: true

module Packages
  module Debian
    class ProcessPackageFileService
      include ExclusiveLeaseGuard
      include Gitlab::Utils::StrongMemoize

      SOURCE_FIELD_SPLIT_REGEX = /[ ()]/.freeze
      # used by ExclusiveLeaseGuard
      DEFAULT_LEASE_TIMEOUT = 1.hour.to_i.freeze

      def initialize(package_file, creator, distribution_name, component_name)
        @package_file = package_file
        @creator = creator
        @distribution_name = distribution_name
        @component_name = component_name
      end

      def execute
        try_obtain_lease do
          validate!

          @package_file.transaction do
            update_file_metadata
          end

          ::Packages::Debian::GenerateDistributionWorker.perform_async(:project, package.debian_distribution.id)
        end
      end

      private

      def validate!
        raise ArgumentError, 'package file without Debian metadata' unless @package_file.debian_file_metadatum
        raise ArgumentError, 'already processed package file' unless @package_file.debian_file_metadatum.unknown?

        return if file_metadata[:file_type] == :deb || file_metadata[:file_type] == :udeb

        raise ArgumentError, "invalid package file type: #{file_metadata[:file_type]}"
      end

      def update_file_metadata
        ::Packages::UpdatePackageFileService.new(@package_file, package_id: package.id)
          .execute

        # Force reload from database, as package has changed
        @package_file.reload_package

        @package_file.debian_file_metadatum.update!(
          file_type: file_metadata[:file_type],
          component: @component_name,
          architecture: file_metadata[:architecture],
          fields: file_metadata[:fields]
        )
      end

      def package
        strong_memoize(:package) do
          package_name = file_metadata[:fields]['Package']
          package_version = file_metadata[:fields]['Version']

          if file_metadata[:fields]['Source']
            # "sample" or "sample (1.2.3~alpha2)"
            source_field_parts = file_metadata[:fields]['Source'].split(SOURCE_FIELD_SPLIT_REGEX)
            package_name = source_field_parts[0]
            package_version = source_field_parts[2] || package_version
          end

          params = {
            'name': package_name,
            'version': package_version,
            'distribution_name': @distribution_name
          }
          response = Packages::Debian::FindOrCreatePackageService.new(project, @creator, params).execute
          response.payload[:package]
        end
      end

      def file_metadata
        strong_memoize(:metadata) do
          ::Packages::Debian::ExtractMetadataService.new(@package_file).execute
        end
      end

      def project
        @package_file.package.project
      end

      # used by ExclusiveLeaseGuard
      def lease_key
        "packages:debian:process_package_file_service:package_file:#{@package_file.id}"
      end

      # used by ExclusiveLeaseGuard
      def lease_timeout
        DEFAULT_LEASE_TIMEOUT
      end
    end
  end
end
