# frozen_string_literal: true

module QA
  module Page
    module Component
      module GroupsFilter
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/assets/javascripts/groups/components/overview_tabs.vue' do
            element 'groups-filter-field'
          end

          base.view 'app/views/shared/groups/_search_form.html.haml' do
            element 'groups-filter-field'
          end

          base.view 'app/assets/javascripts/groups/components/groups.vue' do
            element 'groups-list-tree-container'
          end
        end

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
          fill_element('groups-filter-field', name).send_keys(:return)
          # Loading starts a moment after `return` is sent. We mustn't jump ahead
          wait_for_requests if spinner_exists?
          has_element?('groups-list-tree-container', wait: 1)
        end
      end
    end
  end
end
