# frozen_string_literal: true

module Gitlab
  module DependencyLinker
    class PodspecLinker < MethodLinker
      include Cocoapods

      STRING_REGEX = /['"](?<name>[^'"]+)['"]/

      self.file_type = :podspec

      private

      def link_dependencies
        link_method_call('homepage', URL_REGEX, &:itself)

        link_regex(/(git:|:git\s*=>)\s*['"](?<name>#{URL_REGEX})['"]/o, &:itself)

        link_method_call('license', &method(:license_url))
        link_regex(/license\s*=\s*\{\s*(type:|:type\s*=>)\s*#{STRING_REGEX}/o, &method(:license_url))

        link_method_call('dependency', &method(:package_url))
      end
    end
  end
end
