# frozen_string_literal: true

module Gitlab
  module DependencyLinker
    class PodfileLinker < GemfileLinker
      include Cocoapods

      self.package_keyword = :pod
      self.file_type = :podfile

      private

      def link_packages
        packages = parse_packages

        return unless packages

        packages.each do |package|
          link_method_call('pod', package.name) do
            external_url(package.name, package.external_ref)
          end
        end
      end
    end
  end
end
