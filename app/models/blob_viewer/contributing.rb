# frozen_string_literal: true

module BlobViewer
  class Contributing < Base
    include Auxiliary
    include Static

    self.partial_name = 'contributing'
    self.file_types = %i[contributing]
    self.binary = false
  end
end
