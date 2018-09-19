# frozen_string_literal: true

module DiffViewer
  module ClientSide
    extend ActiveSupport::Concern

    included do
      self.collapse_limit = 1.megabyte
      self.size_limit = 10.megabytes
    end
  end
end
