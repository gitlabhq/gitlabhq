# frozen_string_literal: true

module Gitlab
  module DependencyLinker
    class PackageJsonLinker < JsonLinker
      self.file_type = :package_json

      private

      def link_dependencies
        link_json('license', &method(:license_url))
        link_json(%w[homepage url], URL_REGEX, &:itself)

        link_packages
      end

      def link_packages
        link_packages_at_key("dependencies")
        link_packages_at_key("devDependencies")
      end

      def link_packages_at_key(key)
        dependencies = json[key]
        return unless dependencies
        return unless dependencies.is_a?(Hash)

        dependencies.each do |name, version|
          external_url = external_url(name, version)

          link_json(name, version, link: :key) { external_url }
          link_json(name) { external_url }
        end
      end

      def package_url(name)
        "https://npmjs.com/package/#{name}"
      end
    end
  end
end
