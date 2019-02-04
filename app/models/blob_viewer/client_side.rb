# frozen_string_literal: true

module BlobViewer
  module ClientSide
    extend ActiveSupport::Concern

    included do
      self.load_async = false
      self.collapse_limit = 10.megabytes
      self.size_limit = 50.megabytes
    end
  end
end
