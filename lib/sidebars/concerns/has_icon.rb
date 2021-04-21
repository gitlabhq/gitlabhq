# frozen_string_literal: true

# This module has the necessary methods to show
# sprites or images next to the menu item.
module Sidebars
  module Concerns
    module HasIcon
      def sprite_icon
        nil
      end

      def sprite_icon_html_options
        {}
      end

      def image_path
        nil
      end

      def image_html_options
        {}
      end

      def icon_or_image?
        sprite_icon || image_path
      end
    end
  end
end
