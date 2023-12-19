# frozen_string_literal: true

module DiffViewer
  module Simple
    extend ActiveSupport::Concern

    included do
      self.type = :simple
      self.switcher_icon = 'code'

      def self.switcher_title
        _('source diff')
      end
    end
  end
end
