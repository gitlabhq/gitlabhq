module BlobViewer
  class License < Base
    # We treat the License viewer as if it renders the content client-side,
    # so that it doesn't attempt to load the entire blob contents and is
    # rendered synchronously instead of loaded asynchronously.
    include ClientSide
    include Auxiliary

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
