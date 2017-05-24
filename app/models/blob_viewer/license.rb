module BlobViewer
  class License < Base
    include Auxiliary
    include Static

    self.partial_name = 'license'
    self.file_types = %i(license)
    self.binary = false

    def license
      blob.project.repository.license
    end

    def render_error
      return if license

      :unknown_license
    end
  end
end
