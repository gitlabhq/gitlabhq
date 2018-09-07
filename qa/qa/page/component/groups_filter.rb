# frozen_string_literal: true

module QA
  module Page
    module Component
      module GroupsFilter
        def self.included(base)
          base.view 'app/views/shared/groups/_search_form.html.haml' do
            element :groups_filter, 'search_field_tag :filter'
            element :groups_filter_placeholder, 'Search by name'
          end

          base.view 'app/views/shared/groups/_empty_state.html.haml' do
            element :groups_empty_state
          end

          base.view 'app/assets/javascripts/groups/components/groups.vue' do
            element :groups_list_tree_container
          end
        end

        private

        def filter_by_name(name)
          wait(reload: false) do
            page.has_css?(element_selector_css(:groups_empty_state)) ||
              page.has_css?(element_selector_css(:groups_list_tree_container))
          end

          fill_in 'Search by name', with: name
        end
      end
    end
  end
end
