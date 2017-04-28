module BlobViewer
  class Download < Base
    include Simple
    # We treat the Download viewer as if it renders the content client-side,
    # so that it doesn't attempt to load the entire blob contents and is
    # rendered synchronously instead of loaded asynchronously.
    include ClientSide

    self.partial_name = 'download'
    self.binary = true

    # We can always render the Download viewer, even if the blob is in LFS or too large.
    def render_error
      nil
    end
  end
end
