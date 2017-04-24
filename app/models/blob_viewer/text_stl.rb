module BlobViewer
  class TextSTL < Base
    include Rich
    include ClientSide

    self.partial_name = 'stl'
    self.extensions = %w(stl)
    self.binary = false
  end
end
