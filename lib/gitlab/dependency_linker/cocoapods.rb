# frozen_string_literal: true

module Gitlab
  module DependencyLinker
    module Cocoapods
      def package_url(name)
        package = name.split("/", 2).first
        "https://cocoapods.org/pods/#{package}"
      end
    end
  end
end
