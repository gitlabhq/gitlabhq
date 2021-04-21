# frozen_string_literal: true

module Sidebars
  module Concerns
    module Renderable
      # This method will control whether the menu or menu_item
      # should be rendered. It will be overriden by specific
      # classes.
      def render?
        true
      end
    end
  end
end
