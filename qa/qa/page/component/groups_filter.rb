# frozen_string_literal: true

module QA
  module Page
    module Component
      module GroupsFilter
        extend QA::Page::PageConcern

        private

        # Check if a group exists in private or public tab
        # @param name [String] group name
        # @return [Boolean] whether a group with given name exists
        def has_filtered_group?(name)
          filter_group(name)

          page.has_link?(name, wait: 0) # element containing link to group
        end

        # Filter by group name
        # @param name [String] group name
        # @return [Boolean] whether the filter returned any group
        def filter_group(name)
          # Clicking the term input swaps it for the token segment input, so find the input again
          find_element('filtered-search-term-input').click
          find_element('filtered-search-token-segment-input').set(name)
          click_element 'search-button'
          # Loading starts a moment after `return` is sent. We mustn't jump ahead
          wait_for_requests if spinner_exists?
          has_element?('nested-groups-projects-list', wait: 1)
        end
      end
    end
  end
end
