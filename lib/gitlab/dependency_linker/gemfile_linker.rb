module Gitlab
  module DependencyLinker
    class GemfileLinker < MethodLinker
      self.file_type = :gemfile

      private

      def link_dependencies
        link_urls
        link_packages
      end

      def link_urls
        # Link `github: "user/repo"` to https://github.com/user/repo
        link_regex(/(github:|:github\s*=>)\s*['"](?<name>[^'"]+)['"]/, &method(:github_url))

        # Link `git: "https://gitlab.example.com/user/repo"` to https://gitlab.example.com/user/repo
        link_regex(/(git:|:git\s*=>)\s*['"](?<name>#{URL_REGEX})['"]/, &:itself)

        # Link `source "https://rubygems.org"` to https://rubygems.org
        link_method_call('source', URL_REGEX, &:itself)
      end

      def link_packages
        # Link `gem "package_name"` to https://rubygems.org/gems/package_name
        link_method_call('gem') do |name|
          "https://rubygems.org/gems/#{name}"
        end
      end
    end
  end
end
