# frozen_string_literal: true

# This module introduces the logic to show the "pill" element
# next to the menu item, indicating the a count.
module Sidebars
  module Concerns
    module HasPill
      include ActionView::Helpers::NumberHelper

      def has_pill?
        false
      end

      # In this method we will need to provide the query
      # to retrieve the elements count
      def pill_count; end

      # The GraphQL field name from `SidebarType` that will be used
      # as the pill count for this menu item.
      # This is used when the count is expensive and we want to fetch it separately
      # from GraphQL.
      def pill_count_field; end

      def pill_html_options
        {}
      end

      def format_cached_count(threshold, count)
        if count > threshold
          number_to_human(
            count,
            units: { thousand: 'k', million: 'm' }, precision: 1, significant: false, format: '%n%u'
          )
        else
          number_with_delimiter(count)
        end
      end
    end
  end
end
