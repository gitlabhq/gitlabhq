# frozen_string_literal: true

module BlobViewer
  class CSV < Base
    include Rich
    include ClientSide

    self.binary = false
    self.extensions = %w[csv]
    self.partial_name = 'csv'
    self.switcher_icon = 'table'
  end
end
