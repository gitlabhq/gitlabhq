module BlobViewer
  module ClientSide
    extend ActiveSupport::Concern

    included do
      self.client_side = true
      self.max_size = 10.megabytes
      self.absolute_max_size = 50.megabytes
    end
  end
end
