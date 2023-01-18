# frozen_string_literal: true

module QA
  module Page
    module Component
      module GroupsFilter
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/assets/javascripts/groups/components/overview_tabs.vue' do
            element :groups_filter_field
          end

          base.view 'app/assets/javascripts/groups/components/groups.vue' do
            element :groups_list_tree_container
          end

          base.view 'app/views/dashboard/_groups_head.html.haml' do
            element :public_groups_tab
          end
        end

        private

        # Check if a group exists in private or public tab
        # @param name [String] group name
        # @return [Boolean] whether a group with given name exists
        def has_filtered_group?(name)
          filter_group(name)
          return true if page.has_link?(name, wait: 0) # element containing link to group

          return false unless has_element?(:public_groups_tab, wait: 0)

          # Check public groups
          click_element(:public_groups_tab)
          filter_group(name)
          page.has_link?(name, wait: 0)
        end

        # Filter by group name
        # @param name [String] group name
        # @return [Boolean] whether the filter returned any group
        def filter_group(name)
          fill_element(:groups_filter_field, name).send_keys(:return)
          finished_loading?
          has_element?(:groups_list_tree_container, wait: 1)
        end
      end
    end
  end
end
