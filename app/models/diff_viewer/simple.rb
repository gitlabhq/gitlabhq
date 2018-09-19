# frozen_string_literal: true

module DiffViewer
  module Simple
    extend ActiveSupport::Concern

    included do
      self.type = :simple
      self.switcher_icon = 'code'
      self.switcher_title = 'source diff'
    end
  end
end
