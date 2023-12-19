# frozen_string_literal: true

module DiffViewer
  module Rich
    extend ActiveSupport::Concern

    included do
      self.type = :rich
      self.switcher_icon = 'doc-text'

      def self.switcher_title
        _('rendered diff')
      end
    end
  end
end
