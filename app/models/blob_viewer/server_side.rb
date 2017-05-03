module BlobViewer
  module ServerSide
    extend ActiveSupport::Concern

    included do
      self.client_side = false
      self.max_size = 2.megabytes
      self.absolute_max_size = 5.megabytes
    end
  end
end
