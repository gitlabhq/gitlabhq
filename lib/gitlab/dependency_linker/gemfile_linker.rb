module Gitlab
  module DependencyLinker
    class GemfileLinker < BaseLinker
      self.file_type = :gemfile

      private

      def link_dependencies
        # Link `gem "package_name"` to https://rubygems.org/gems/package_name
        link_method_call("gem")

        # Link `github: "user/repo"` to https://github.com/user/repo
        link_regex(/(github:|:github\s*=>)\s*['"](?<name>[^'"]+)['"]/) do |name|
          "https://github.com/#{name}"
        end

        # Link `git: "https://gitlab.example.com/user/repo"` to https://gitlab.example.com/user/repo
        link_regex(%r{(git:|:git\s*=>)\s*['"](?<name>https?://[^'"]+)['"]}) { |url| url }

        # Link `source "https://rubygems.org"` to https://rubygems.org
        link_method_call("source", %r{https?://[^'"]+}) { |url| url }
      end

      def package_url(name)
        "https://rubygems.org/gems/#{name}"
      end
    end
  end
end
