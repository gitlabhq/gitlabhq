# frozen_string_literal: true

# This module introduces the logic to show the "pill" element
# next to the menu item, indicating the a count.
module Sidebars
  module Concerns
    module HasPill
      def has_pill?
        false
      end

      # In this method we will need to provide the query
      # to retrieve the elements count
      def pill_count
        raise NotImplementedError
      end

      def pill_html_options
        {}
      end
    end
  end
end
