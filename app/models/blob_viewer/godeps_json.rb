# frozen_string_literal: true

module BlobViewer
  class GodepsJson < DependencyManager
    include Static

    self.file_types = %i[godeps_json]

    def manager_name
      'godep'
    end

    def manager_url
      'https://github.com/tools/godep'
    end
  end
end
