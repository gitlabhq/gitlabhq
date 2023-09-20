# frozen_string_literal: true

module BlobViewer
  class Notebook < Base
    include Rich
    include ClientSide

    self.partial_name = 'notebook'
    self.extensions = %w[ipynb]
    self.binary = false
    self.switcher_icon = 'doc-text'
    self.switcher_title = 'notebook'
  end
end
