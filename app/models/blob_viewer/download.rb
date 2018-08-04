# frozen_string_literal: true

module BlobViewer
  class Download < Base
    include Simple
    include Static

    self.partial_name = 'download'
    self.binary = true
  end
end
