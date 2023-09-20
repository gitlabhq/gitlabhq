# frozen_string_literal: true

module BlobViewer
  class PodspecJson < Podspec
    self.file_types = %i[podspec_json]

    def package_name
      @package_name ||= fetch_from_json('name')
    end
  end
end
