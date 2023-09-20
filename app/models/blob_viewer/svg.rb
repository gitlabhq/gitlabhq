# frozen_string_literal: true

module BlobViewer
  class SVG < Base
    include Rich
    include ServerSide

    self.partial_name = 'svg'
    self.extensions = %w[svg]
    self.binary = false
    self.switcher_icon = 'doc-image'
    self.switcher_title = 'image'
  end
end
