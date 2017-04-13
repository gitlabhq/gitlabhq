module BlobViewer
  class Download < Base
    include Simple
    include ServerSide

    self.partial_name = 'download'
    self.text_based = false

    def render_error(*)
      nil
    end
  end
end
