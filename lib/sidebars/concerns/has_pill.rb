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
      def pill_count
        raise NotImplementedError
      end

      def pill_html_options
        {}
      end

      def format_cached_count(count_service, count)
        if count > count_service::CACHED_COUNT_THRESHOLD
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
