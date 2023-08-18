# frozen_string_literal: true

module Gitlab
  module DependencyLinker
    class ComposerJsonLinker < PackageJsonLinker
      self.file_type = :composer_json

      private

      def link_packages
        link_packages_at_key("require")
        link_packages_at_key("require-dev")
      end

      def package_url(name)
        "https://packagist.org/packages/#{name}" if /\A#{REPO_REGEX}\z/o.match?(name)
      end
    end
  end
end
