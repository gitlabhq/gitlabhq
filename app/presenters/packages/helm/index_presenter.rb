# frozen_string_literal: true

module Packages
  module Helm
    class IndexPresenter
      include API::Helpers::RelatedResourcesHelpers

      API_VERSION = 'v1'
      CHANNEL = 'channel'
      INDEX_YAML_SUFFIX = "/#{CHANNEL}/index.yaml"

      def initialize(project, project_id_param, package_files)
        @project = project
        @project_id_param = project_id_param
        @package_files = package_files
      end

      def api_version
        API_VERSION
      end

      def entries
        files = @package_files.preload_helm_file_metadata
        result = Hash.new { |h, k| h[k] = [] }

        files.find_each do |package_file|
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
    end
  end
end
