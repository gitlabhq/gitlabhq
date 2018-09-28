# frozen_string_literal: true

module BlobViewer
  class Empty < Base
    include Simple
    include ServerSide

    self.partial_name = 'empty'
  end
end
