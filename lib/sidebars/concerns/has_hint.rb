# frozen_string_literal: true

# This module has the necessary methods to store
# hints for menus. Hints are elements displayed
# when the user hover the menu item.
module Sidebars
  module Concerns
    module HasHint
      def show_hint?
        false
      end

      def hint_html_options
        {}
      end
    end
  end
end
