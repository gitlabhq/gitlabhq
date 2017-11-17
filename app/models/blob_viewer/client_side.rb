module BlobViewer
  module ClientSide
    extend ActiveSupport::Concern

    included do
      self.load_async = false
      self.collapse_limit = 1.byte
      self.size_limit = 1.byte
    end
  end
end
