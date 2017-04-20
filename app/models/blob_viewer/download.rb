module BlobViewer
  class Download < Base
    include Simple
    # We pretend the Download viewer is rendered client-side so that it doesn't
    # attempt to load the entire blob contents.
    include ClientSide

    self.partial_name = 'download'
    self.text_based = false

    def render_error(*)
      nil
    end
  end
end
