# frozen_string_literal: true

module Gitlab
  module Composer
    class VersionIndex
      include API::Helpers::RelatedResourcesHelpers

      def initialize(packages)
        @packages = packages
      end

      def as_json(_options = nil)
        { 'packages' => { @packages.first.name => package_versions_map } }
      end

      def sha
        Digest::SHA256.hexdigest(to_json)
      end

      private

      def package_versions_map
        @packages.each_with_object({}) do |package, map|
          map[package.version] = package_metadata(package)
        end
      end

      def package_metadata(package)
        json = package.composer_metadatum.composer_json

        json.merge('dist' => package_dist(package), 'uid' => package.id, 'version' => package.version)
      end

      def package_dist(package)
        sha = package.composer_metadatum.target_sha
        archive_api_path = api_v4_projects_packages_composer_archives_package_name_path({ id: package.project_id, package_name: package.name, format: '.zip' }, true)

        {
          'type' => 'zip',
          'url' => expose_url(archive_api_path) + "?sha=#{sha}",
          'reference' => sha,
          'shasum' => ''
        }
      end
    end
  end
end
