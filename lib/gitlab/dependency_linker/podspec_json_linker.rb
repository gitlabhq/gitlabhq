# frozen_string_literal: true

module Gitlab
  module DependencyLinker
    class PodspecJsonLinker < JsonLinker
      include Cocoapods

      self.file_type = :podspec_json

      private

      def link_dependencies
        link_json('name', json["name"]) { |value| package_url(value) }
        link_json('license') { |value| license_url(value) }
        link_json(%w[homepage git], URL_REGEX, &:itself)

        link_packages_at_key("dependencies") { |value| package_url(value) }

        json["subspecs"]&.each do |subspec|
          link_packages_at_key("dependencies", subspec) { |value| package_url(value) }
        end
      end

      def link_packages_at_key(key, root = json, &url_proc)
        dependencies = root[key]
        return unless dependencies

        dependencies.each do |name, _|
          link_regex(/"(?<name>#{Regexp.escape(name)})":\s*\[/, &url_proc)
        end
      end
    end
  end
end
