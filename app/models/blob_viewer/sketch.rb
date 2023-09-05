# frozen_string_literal: true

module BlobViewer
  class Sketch < Base
    include Rich
    include ClientSide

    self.partial_name = 'sketch'
    self.extensions = %w[sketch]
    self.binary = true
    self.switcher_icon = 'doc-image'
    self.switcher_title = 'preview'
  end
end
