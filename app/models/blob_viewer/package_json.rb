# frozen_string_literal: true

module BlobViewer
  class PackageJson < DependencyManager
    include ServerSide

    self.file_types = %i[package_json]

    def manager_name
      yarn? ? 'yarn' : 'npm'
    end

    def yarn?
      fetch_from_json('engines', 'yarn').present?
    end

    def manager_url
      yarn? ? 'https://yarnpkg.com/' : 'https://www.npmjs.com/'
    end

    def package_name
      @package_name ||= fetch_from_json('name')
    end

    def package_type
      private? ? 'private package' : super
    end

    def package_url
      private? ? homepage : npm_url
    end

    private

    def private?
      !!fetch_from_json('private')
    end

    def homepage
      url = fetch_from_json('homepage')
      url if Gitlab::UrlSanitizer.valid?(url)
    end

    def npm_url
      if yarn?
        "https://yarnpkg.com/package/#{package_name}"
      else
        "https://www.npmjs.com/package/#{package_name}"
      end
    end
  end
end
