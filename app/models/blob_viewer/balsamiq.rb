# frozen_string_literal: true

module BlobViewer
  class Balsamiq < Base
    include Rich
    include ClientSide

    self.partial_name = 'balsamiq'
    self.extensions = %w(bmpr)
    self.binary = true
    self.switcher_icon = 'doc-image'
    self.switcher_title = 'preview'
  end
end
