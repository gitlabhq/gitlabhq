# frozen_string_literal: true

module BlobViewer
  module Simple
    extend ActiveSupport::Concern

    included do
      self.type = :simple
      self.switcher_icon = 'code'
      self.switcher_title = 'source'
    end
  end
end
