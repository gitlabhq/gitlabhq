module BlobViewer
  class Empty < Base
    include Simple
    include ServerSide

    self.partial_name = 'empty'
    self.text_based = false
  end
end
