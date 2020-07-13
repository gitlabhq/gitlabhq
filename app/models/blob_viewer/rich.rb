# frozen_string_literal: true

module BlobViewer
  module Rich
    extend ActiveSupport::Concern

    included do
      self.type = :rich
      self.switcher_icon = 'doc-text'
      self.switcher_title = 'rendered file'
    end
  end
end
