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
        path = api_v4_group___packages_composer_package_name_path({ id: @group.id, package_name: '%package%$%hash%', format: '.json' }, true)
        { 'packages' => [], 'provider-includes' => { 'p/%hash%.json' => { 'sha256' => provider_sha } }, 'providers-url' => path }
      end

      def provider
        { 'providers' => providers_map }
      end

      def package_versions(packages = @packages)
        package_versions_index(packages).as_json
      end

      private

      def package_versions_sha(packages = @packages)
        package_versions_index(packages).sha
      end

      def package_versions_index(packages)
        ::Gitlab::Composer::VersionIndex.new(packages)
      end

      def providers_map
        map = {}

        @packages.group_by(&:name).each_pair do |package_name, packages|
          map[package_name] = { 'sha256' => package_versions_sha(packages) }
        end

        map
      end

      def provider_sha
        Digest::SHA256.hexdigest(provider.to_json)
      end
    end
  end
end
