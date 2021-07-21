# frozen_string_literal: true

# This module has the necessary methods to render
# menus using a custom partial
module Sidebars
  module Concerns
    module HasPartial
      def menu_partial
        nil
      end

      def menu_partial_options
        {}
      end

      def menu_with_partial?
        menu_partial.present?
      end
    end
  end
end
