# frozen_string_literal: true

module BlobViewer
  class BinarySTL < Base
    include Rich
    include ClientSide

    self.partial_name = 'stl'
    self.extensions = %w[stl]
    self.binary = true
  end
end
