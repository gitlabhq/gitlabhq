module Gitlab
  module DependencyLinker
    class ComposerJsonLinker < PackageJsonLinker
      self.file_type = :composer_json

      private

      def link_packages
        link_packages_at_key("require", &method(:package_url))
        link_packages_at_key("require-dev", &method(:package_url))
      end

      def package_url(name)
        "https://packagist.org/packages/#{name}" if name =~ /\A#{REPO_REGEX}\z/
      end
    end
  end
end
