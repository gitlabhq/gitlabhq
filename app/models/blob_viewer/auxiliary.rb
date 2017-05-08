module BlobViewer
  module Auxiliary
    extend ActiveSupport::Concern

    included do
      self.loading_partial_name = 'loading_auxiliary'
      self.type = :auxiliary
      self.max_size = 100.kilobytes
      self.absolute_max_size = 100.kilobytes
    end
  end
end
