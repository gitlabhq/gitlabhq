# frozen_string_literal: true

module BlobViewer
  class PDF < Base
    include Rich
    include ClientSide

    self.partial_name = 'pdf'
    self.extensions = %w(pdf)
    self.binary = true
    self.switcher_icon = 'file-pdf-o'
    self.switcher_title = 'PDF'
  end
end
