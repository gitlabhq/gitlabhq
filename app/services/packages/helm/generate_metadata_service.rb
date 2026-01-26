# frozen_string_literal: true

module Packages
  module Helm
    class GenerateMetadataService
      include API::Helpers::RelatedResourcesHelpers

      API_VERSION = 'v1'
      CHANNEL = 'channel'
      INDEX_YAML_SUFFIX = "/#{CHANNEL}/index.yaml".freeze
      EMPTY_HASH = {}.freeze
      PACKAGES_BATCH_SIZE = 300

      def initialize(project_id_param, channel, packages)
        @project_id_param = project_id_param
        @channel = channel
        @packages = packages
      end

      def execute
        metadata = {
          api_version: api_version,
          entries: entries,
          generated: generated,
          server_info: server_info
        }

        ServiceResponse.success(payload: metadata)
      end

      private

      attr_reader :project_id_param, :channel, :packages

      def api_version
        API_VERSION
      end

      def entries
        return EMPTY_HASH unless channel.present?

        result = Hash.new { |h, k| h[k] = [] }

        packages.each_batch(of: PACKAGES_BATCH_SIZE) do |chunk_packages|
          most_recent_package_files(chunk_packages).each do |package_file|
            name = package_file.helm_metadata['name']
            result[name] << package_file.helm_metadata.merge({
              'created' => package_file.created_at.utc.strftime('%Y-%m-%dT%H:%M:%S.%NZ'),
              'digest' => package_file.file_sha256,
              'urls' => ["charts/#{package_file.file_name}"]
            })
          end
        end

        result
      end

      def generated
        Time.zone.now.utc.strftime('%Y-%m-%dT%H:%M:%S.%NZ')
      end

      def server_info
        path = api_v4_projects_packages_helm_index_yaml_path(
          id: ERB::Util.url_encode(project_id_param),
          channel: CHANNEL
        )
        {
          'contextPath' => path.delete_suffix(INDEX_YAML_SUFFIX)
        }
      end

      def most_recent_package_files(packages)
        ::Packages::PackageFile.most_recent_for_helm_with_channel(
          packages, channel
        ).preload_helm_file_metadata
      end
    end
  end
end
