# frozen_string_literal: true

module BlobViewer
  class OpenApi < Base
    include Rich
    include ClientSide

    self.partial_name = 'openapi'
    self.file_types = %i(openapi)
    self.binary = false
    # TODO: get an icon for OpenAPI
    self.switcher_icon = 'file-pdf-o'
    self.switcher_title = 'OpenAPI'
  end
end
