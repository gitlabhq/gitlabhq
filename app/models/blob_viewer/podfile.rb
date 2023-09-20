# frozen_string_literal: true

module BlobViewer
  class Podfile < DependencyManager
    include Static

    self.file_types = %i[podfile]

    def manager_name
      'CocoaPods'
    end

    def manager_url
      'https://cocoapods.org/'
    end
  end
end
