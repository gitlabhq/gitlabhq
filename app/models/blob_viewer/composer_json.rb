module BlobViewer
  class ComposerJson < DependencyManager
    include ServerSide

    self.file_types = %i(composer_json)

    def manager_name
      'Composer'
    end

    def manager_url
      'https://getcomposer.org/'
    end

    def package_name
      @package_name ||= package_name_from_json('name')
    end

    def package_url
      "https://packagist.org/packages/#{package_name}"
    end
  end
end
