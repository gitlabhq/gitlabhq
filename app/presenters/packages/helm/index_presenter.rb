# frozen_string_literal: true

module Packages
  module Helm
    class IndexPresenter
      include API::Helpers::RelatedResourcesHelpers

      API_VERSION = 'v1'
      CHANNEL = 'channel'
      INDEX_YAML_SUFFIX = "/#{CHANNEL}/index.yaml"
      EMPTY_HASH = {}.freeze

      def initialize(project_id_param, channel, packages)
        @project_id_param = project_id_param
        @channel = channel
        @packages = packages
      end

      def api_version
        API_VERSION
      end

      def entries
        return EMPTY_HASH unless @channel.present?

        result = Hash.new { |h, k| h[k] = [] }

        # this .each is safe as we have max 300 objects
        most_recent_package_files.each do |package_file|
          name = package_file.helm_metadata['name']
          result[name] << package_file.helm_metadata.merge({
            'created' => package_file.created_at.utc.strftime('%Y-%m-%dT%H:%M:%S.%NZ'),
            'digest' => package_file.file_sha256,
            'urls' => ["charts/#{package_file.file_name}"]
          })
        end

        result
      end

      def generated
        Time.zone.now.utc.strftime('%Y-%m-%dT%H:%M:%S.%NZ')
      end

      def server_info
        path = api_v4_projects_packages_helm_index_yaml_path(
          id: ERB::Util.url_encode(@project_id_param),
          channel: CHANNEL
        )
        {
          'contextPath' => path.delete_suffix(INDEX_YAML_SUFFIX)
        }
      end

      private

      def most_recent_package_files
        ::Packages::PackageFile.most_recent_for(
          @packages,
          extra_join: :helm_file_metadatum,
          extra_where: { packages_helm_file_metadata: { channel: @channel } }
        ).preload_helm_file_metadata
      end
    end
  end
end
