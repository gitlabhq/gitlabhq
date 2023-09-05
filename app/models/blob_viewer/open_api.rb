# frozen_string_literal: true

module BlobViewer
  class OpenApi < Base
    include Rich
    include ClientSide

    self.partial_name = 'openapi'
    self.file_types = %i[openapi]
    self.binary = false
    self.switcher_icon = 'api'
  end
end
