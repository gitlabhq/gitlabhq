# frozen_string_literal: true

module BlobViewer
  module Rich
    extend ActiveSupport::Concern

    included do
      self.type = :rich
      self.switcher_icon = 'file-text-o'
      self.switcher_title = 'rendered file'
    end
  end
end
