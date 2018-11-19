# frozen_string_literal: true

module Gitlab
  module DependencyLinker
    class PackageJsonLinker < JsonLinker
      self.file_type = :package_json

      private

      def link_dependencies
        link_json('name', json["name"], &method(:package_url))
        link_json('license', &method(:license_url))
        link_json(%w[homepage url], URL_REGEX, &:itself)

        link_packages
      end

      def link_packages
        link_packages_at_key("dependencies", &method(:package_url))
        link_packages_at_key("devDependencies", &method(:package_url))
      end

      def link_packages_at_key(key, &url_proc)
        dependencies = json[key]
        return unless dependencies

        dependencies.each do |name, version|
          link_json(name, version, link: :key, &url_proc)

          link_json(name) do |value|
            case value
            when /\A#{URL_REGEX}\z/
              value
            when /\A#{REPO_REGEX}\z/
              github_url(value)
            end
          end
        end
      end

      def package_url(name)
        "https://npmjs.com/package/#{name}"
      end
    end
  end
end
