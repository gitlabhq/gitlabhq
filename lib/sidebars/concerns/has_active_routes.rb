# frozen_string_literal: true

module Sidebars
  module Concerns
    module HasActiveRoutes
      # This method will indicate for which paths or
      # controllers, the menu or menu item should
      # be set as active.
      #
      # The returned values are passed to the `nav_link` helper method,
      # so the params can be either `path`, `page`, `controller`.
      # Param 'action' is not supported.
      def active_routes
        {}
      end
    end
  end
end
