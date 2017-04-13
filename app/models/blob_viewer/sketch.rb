module BlobViewer
  class Sketch < Base
    include Rich
    include ClientSide

    self.partial_name = 'sketch'
    self.extensions = %w(sketch)
    self.text_based = false
    self.switcher_icon = 'file-image-o'
    self.switcher_title = 'preview'
  end
end
