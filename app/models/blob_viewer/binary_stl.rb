module BlobViewer
  class BinarySTL < Base
    include Rich
    include ClientSide

    self.partial_name = 'stl'
    self.extensions = %w(stl)
    self.text_based = false
  end
end
