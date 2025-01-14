# frozen_string_literal: true

module Gitlab
  module DependencyLinker
    class GemfileLinker < MethodLinker
      class_attribute :package_keyword

      self.package_keyword = :gem
      self.file_type = :gemfile

      GITHUB_REGEX = /(?:github:|:github\s*=>)\s*['"](?<name>[^'"]+)['"]/
      GIT_REGEX = /(?:git:|:git\s*=>)\s*['"](?<name>#{URL_REGEX})['"]/

      private

      def link_dependencies
        link_urls
        link_packages
      end

      def link_urls
        # Link `github: "user/repo"` to https://github.com/user/repo
        link_regex(GITHUB_REGEX, &method(:github_url))

        # Link `git: "https://gitlab.example.com/user/repo"` to https://gitlab.example.com/user/repo
        link_regex(GIT_REGEX, &:itself)

        # Link `source "https://rubygems.org"` to https://rubygems.org
        link_method_call('source', URL_REGEX, &:itself)
      end

      def link_packages
        packages = parse_packages

        return if packages.blank?

        packages.each do |package|
          link_method_call('gem', package.name) do
            external_url(package.name, package.external_ref)
          end
        end
      end

      def package_url(name)
        "https://rubygems.org/gems/#{name}"
      end

      def parse_packages
        parser = Gitlab::DependencyLinker::Parser::Gemfile.new(plain_text)
        parser.parse(keyword: self.class.package_keyword)
      end
    end
  end
end
