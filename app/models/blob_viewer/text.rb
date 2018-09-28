# frozen_string_literal: true

module BlobViewer
  class Text < Base
    include Simple
    include ServerSide

    self.partial_name = 'text'
    self.binary = false
    self.collapse_limit = 1.megabyte
    self.size_limit = 10.megabytes
  end
end
