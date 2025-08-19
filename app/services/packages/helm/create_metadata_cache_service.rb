# frozen_string_literal: true

module Packages
  module Helm
    class CreateMetadataCacheService
      include Gitlab::Utils::StrongMemoize
      include ExclusiveLeaseGuard

      # used by ExclusiveLeaseGuard
      DEFAULT_LEASE_TIMEOUT = 1.hour.to_i.freeze

      def initialize(project, channel)
        @project = project
        @channel = channel
      end

      def execute
        try_obtain_lease do
          Packages::Helm::MetadataCache
            .find_or_build(project_id: project.id, channel: channel)
            .update!(
              file: CarrierWaveStringFile.new(metadata_content),
              size: metadata_content.bytesize
            )
        end

        ServiceResponse.success
      rescue ActiveRecord::RecordInvalid => e
        ServiceResponse.error(message: e.message)
      end

      private

      attr_reader :channel, :project

      def metadata_content
        index_content = ::API::Entities::Helm::Index.represent(metadata.payload)
        yaml_content = index_content.serializable_hash.stringify_keys.to_yaml

        double_quote_app_version(yaml_content)
      end
      strong_memoize_attr :metadata_content

      def double_quote_app_version(yaml_content)
        yaml_content.gsub(Gitlab::Regex.helm_index_app_version_quote_regex, '\1"\2"')
      end

      def packages
        ::Packages::Helm::PackagesFinder.new(project, channel, with_recent_limit: false).execute
      end

      def metadata
        ::Packages::Helm::GenerateMetadataService.new(project.id, channel, packages).execute
      end

      # used by ExclusiveLeaseGuard
      def lease_key
        "packages:helm:create_metadata_cache_service:metadata_caches:#{project.id}_#{channel}"
      end

      # used by ExclusiveLeaseGuard
      def lease_timeout
        DEFAULT_LEASE_TIMEOUT
      end
    end
  end
end
