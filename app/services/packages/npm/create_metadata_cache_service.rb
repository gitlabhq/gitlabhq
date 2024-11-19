# frozen_string_literal: true

module Packages
  module Npm
    class CreateMetadataCacheService
      include Gitlab::Utils::StrongMemoize
      include ExclusiveLeaseGuard

      # used by ExclusiveLeaseGuard
      DEFAULT_LEASE_TIMEOUT = 1.hour.to_i.freeze

      def initialize(project, package_name)
        @project = project
        @package_name = package_name
      end

      def execute
        try_obtain_lease do
          Packages::Npm::MetadataCache
            .find_or_build(package_name: package_name, project_id: project.id)
            .update!(
              file: CarrierWaveStringFile.new(metadata_content),
              size: metadata_content.bytesize
            )
        end
      end

      private

      attr_reader :package_name, :project

      def metadata_content
        ::API::Entities::NpmPackage.represent(metadata.payload).to_json
      end
      strong_memoize_attr :metadata_content

      def packages
        ::Packages::Npm::PackageFinder
          .new(project: project, params: { package_name: package_name })
          .execute
      end

      def metadata
        Packages::Npm::GenerateMetadataService.new(package_name, packages).execute
      end

      # used by ExclusiveLeaseGuard
      def lease_key
        "packages:npm:create_metadata_cache_service:metadata_caches:#{project.id}_#{package_name}"
      end

      # used by ExclusiveLeaseGuard
      def lease_timeout
        DEFAULT_LEASE_TIMEOUT
      end
    end
  end
end
