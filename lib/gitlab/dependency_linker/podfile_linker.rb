module Gitlab
  module DependencyLinker
    class PodfileLinker < GemfileLinker
      include Cocoapods

      self.file_type = :podfile

      private

      def link_packages
        link_method_call('pod', &method(:package_url))
      end
    end
  end
end
