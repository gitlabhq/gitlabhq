module BlobViewer
  class SVG < Base
    include Rich
    include ServerSide

    self.partial_name = 'svg'
    self.extensions = %w(svg)
    self.text_based = true
    self.switcher_icon = 'picture-o'
    self.switcher_title = 'image'
  end
end
