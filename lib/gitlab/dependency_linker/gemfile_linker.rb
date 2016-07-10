module Gitlab
  module DependencyLinker
    class GemfileLinker < BaseLinker
      def self.support?(blob_name)
        blob_name == 'Gemfile' || blob_name == 'gems.rb'
      end

      private

      def link_dependencies
        # Link `gem "package_name"` to https://rubygems.org/gems/package_name
        link_method_call("gem")

        # Link `github: "user/repo"` to https://github.com/user/repo
        link_regex(/(github:|:github\s*=>)\s*['"](?<name>[^'"]+)['"]/) do |name|
          "https://github.com/#{name}"
        end

        # Link `source "https://rubygems.org"` to https://rubygems.org
        link_method_call("source", %r{https?://[^'"]+}) { |url| url }
      end

      def package_url(name)
        "https://rubygems.org/gems/#{name}"
      end
    end
  end
end
