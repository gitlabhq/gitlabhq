module BlobViewer
  class PackageJson < DependencyManager
    include ServerSide

    self.file_types = %i(package_json)

    def manager_name
      'npm'
    end

    def manager_url
      'https://www.npmjs.com/'
    end

    def package_name
      @package_name ||= package_name_from_json('name')
    end

    def package_url
      "https://www.npmjs.com/package/#{package_name}"
    end
  end
end
