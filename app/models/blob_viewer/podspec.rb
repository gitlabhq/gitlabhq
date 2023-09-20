# frozen_string_literal: true

module BlobViewer
  class Podspec < DependencyManager
    include ServerSide

    self.file_types = %i[podspec]

    def manager_name
      'CocoaPods'
    end

    def manager_url
      'https://cocoapods.org/'
    end

    def package_type
      'pod'
    end

    def package_name
      @package_name ||= package_name_from_method_call('name')
    end

    def package_url
      "https://cocoapods.org/pods/#{package_name}"
    end
  end
end
