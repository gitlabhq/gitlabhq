# frozen_string_literal: true

module DiffViewer
  module Rich
    extend ActiveSupport::Concern

    included do
      self.type = :rich
      self.switcher_icon = 'file-text-o'
      self.switcher_title = 'rendered diff'
    end
  end
end
