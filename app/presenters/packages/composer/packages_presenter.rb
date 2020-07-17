# frozen_string_literal: true

module Packages
  module Composer
    class PackagesPresenter
      include API::Helpers::RelatedResourcesHelpers

      def initialize(group, packages)
        @group = group
        @packages = packages
      end

      def root
        path = api_v4_group___packages_composer_package_name_path({ id: @group.id, package_name: '%package%', format: '.json' }, true)
        { 'packages' => [], 'provider-includes' => { 'p/%hash%.json' => { 'sha256' => provider_sha } }, 'providers-url' => path }
      end

      def provider
        { 'providers' => providers_map }
      end

      def package_versions(packages = @packages)
        { 'packages' => { packages.first.name => package_versions_map(packages) } }
      end

      private

      def package_versions_map(packages)
        packages.each_with_object({}) do |package, map|
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

      def providers_map
        map = {}

        @packages.group_by(&:name).each_pair do |package_name, packages|
          map[package_name] = { 'sha256' => package_versions_sha(packages) }
        end

        map
      end

      def package_versions_sha(packages)
        Digest::SHA256.hexdigest(package_versions(packages).to_json)
      end

      def provider_sha
        Digest::SHA256.hexdigest(provider.to_json)
      end
    end
  end
end
