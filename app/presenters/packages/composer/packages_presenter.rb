# frozen_string_literal: true

module Packages
  module Composer
    class PackagesPresenter
      include API::Helpers::RelatedResourcesHelpers

      def initialize(group, packages, is_v2 = false)
        @group = group
        @packages = packages
        @is_v2 = is_v2
      end

      def root
        v2_path = expose_path(api_v4_group___packages_composer_p2_package_name_path({ id: @group.id, package_name: '%package%', format: '.json' }, true))

        index = {
          'packages' => [],
          'metadata-url' => v2_path
        }

        # if the client is composer v2 then we don't want to
        # include the provider_sha since it is computationally expensive
        # to compute.
        return index if @is_v2

        v1_path = expose_path(api_v4_group___packages_composer_package_name_path({ id: @group.id, package_name: '%package%$%hash%', format: '.json' }, true))

        index.merge!(
          'provider-includes' => {
            'p/%hash%.json' => {
              'sha256' => provider_sha
            }
          },
          'providers-url' => v1_path
        )
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
