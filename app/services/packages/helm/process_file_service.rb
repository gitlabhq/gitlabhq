# frozen_string_literal: true

module Packages
  module Helm
    class ProcessFileService
      include Gitlab::Utils::StrongMemoize
      include ExclusiveLeaseGuard

      ExtractionError = Class.new(StandardError)
      ProtectedPackageError = Class.new(StandardError)

      DEFAULT_LEASE_TIMEOUT = 1.hour.to_i

      def initialize(channel, package_file)
        @channel = channel
        @package_file = package_file
      end

      def execute
        raise ExtractionError, 'Helm chart was not processed - package_file is not set' unless package_file

        if package_protected?
          raise ProtectedPackageError, "Helm chart '#{chart_name}' with version '#{chart_version}' is protected"
        end

        try_obtain_lease do
          temp_package.transaction do
            rename_package_and_set_version
            rename_package_file_and_set_metadata
            cleanup_temp_package
          end
        end

        ::Packages::Helm::CreateMetadataCacheWorker.perform_async(package.project_id, @channel)
      end

      private

      attr_reader :channel, :package_file

      def package_protected?
        service_response =
          ::Packages::Protection::CheckRuleExistenceService.for_push(
            project: @package_file.project,
            current_user: @package_file.package.creator,
            params: { package_name: chart_name, package_type: :helm }
          ).execute

        raise ArgumentError, service_response.message if service_response.error?

        service_response[:protection_rule_exists?]
      end

      def rename_package_and_set_version
        package.update!(
          name: chart_name,
          version: chart_version,
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
        package = ::Packages::Helm::Package.for_projects(package_file.project_id)
                                           .with_name(chart_name)
                                           .with_version(chart_version)
                                           .not_pending_destruction
                                           .last
        package || temp_package
      end
      strong_memoize_attr :package

      def metadata
        ::Packages::Helm::ExtractFileMetadataService.new(package_file).execute
      end
      strong_memoize_attr :metadata

      def chart_name
        metadata['name']
      end

      def chart_version
        metadata['version']
      end

      def file_name
        "#{chart_name}-#{chart_version}.tgz"
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
