# frozen_string_literal: true

module BlobViewer
  class Cartfile < DependencyManager
    include Static

    self.file_types = %i[cartfile]

    def manager_name
      'Carthage'
    end

    def manager_url
      'https://github.com/Carthage/Carthage'
    end
  end
end
