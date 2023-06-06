# frozen_string_literal: true

module Packages
  module Helm
    class ProcessFileService
      include Gitlab::Utils::StrongMemoize
      include ExclusiveLeaseGuard

      ExtractionError = Class.new(StandardError)
      DEFAULT_LEASE_TIMEOUT = 1.hour.to_i

      def initialize(channel, package_file)
        @channel = channel
        @package_file = package_file
      end

      def execute
        raise ExtractionError, 'Helm chart was not processed - package_file is not set' unless package_file

        try_obtain_lease do
          temp_package.transaction do
            rename_package_and_set_version
            rename_package_file_and_set_metadata
            cleanup_temp_package
          end
        end
      end

      private

      attr_reader :channel, :package_file

      def rename_package_and_set_version
        package.update!(
          name: metadata['name'],
          version: metadata['version'],
          status: :default
        )
      end

      def rename_package_file_and_set_metadata
        # Updating file_name updates the path where the file is stored.
        # We must pass the file again so that CarrierWave can handle the update
        package_file.update!(
          file_name: file_name,
          file: package_file.file,
          package_id: package.id,
          helm_file_metadatum_attributes: {
            channel: channel,
            metadata: metadata
          }
        )
      end

      def cleanup_temp_package
        temp_package.destroy if package.id != temp_package.id
      end

      def temp_package
        package_file.package
      end
      strong_memoize_attr :temp_package

      def package
        project_packages = package_file.package.project.packages
        package = project_packages.with_package_type(:helm)
                                  .with_name(metadata['name'])
                                  .with_version(metadata['version'])
                                  .not_pending_destruction
                                  .last
        package || temp_package
      end
      strong_memoize_attr :package

      def metadata
        ::Packages::Helm::ExtractFileMetadataService.new(package_file).execute
      end
      strong_memoize_attr :metadata

      def file_name
        "#{metadata['name']}-#{metadata['version']}.tgz"
      end

      # used by ExclusiveLeaseGuard
      def lease_key
        "packages:helm:process_file_service:package_file:#{package_file.id}"
      end

      # used by ExclusiveLeaseGuard
      def lease_timeout
        DEFAULT_LEASE_TIMEOUT
      end
    end
  end
end
