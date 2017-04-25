module BlobViewer
  class Empty < Base
    include Simple
    include ServerSide

    self.partial_name = 'empty'
    self.binary = true
  end
end
