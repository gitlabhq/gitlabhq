# frozen_string_literal: true

module QA
  module Page
    module Component
      module GroupsFilter
        def self.included(base)
          base.view 'app/views/shared/groups/_search_form.html.haml' do
            element :groups_filter
          end

          base.view 'app/views/shared/groups/_empty_state.html.haml' do
            element :groups_empty_state
          end

          base.view 'app/assets/javascripts/groups/components/groups.vue' do
            element :groups_list_tree_container
          end

          base.view 'app/views/dashboard/groups/_groups.html.haml' do
            element :loading_animation
          end
        end

        private

        # Filter the list of groups/projects by name
        # If submit is true the return key will be sent to the browser to reload
        # the page and fetch only the filtered results
        def filter_by_name(name, submit: false)
          wait(reload: false) do
            # Wait 0 for the empty state element because it is there immediately
            # if there are no groups. Otherwise there's a loading indicator and
            # then groups_list_tree_container appears, which might take longer
            page.has_css?(element_selector_css(:groups_empty_state), wait: 0) ||
              page.has_css?(element_selector_css(:groups_list_tree_container))
          end

          field = find_element :groups_filter
          field.set(name)
          field.send_keys(:return) if submit
        end

        def has_filtered_group?(name)
          # Filter and submit to reload the page and only retrieve the filtered results
          filter_by_name(name, submit: true)

          # Since we submitted after filtering the absence of the loading
          # animation and the presence of groups_list_tree_container means we
          # have the complete filtered list of groups
          wait(reload: false) do
            page.has_no_css?(element_selector_css(:loading_animation)) &&
              page.has_css?(element_selector_css(:groups_list_tree_container))
          end

          # If there are no groups we'll know immediately because we filtered the list
          return if page.has_text?(/No groups or projects matched your search/, wait: 0)

          # The name will be present as filter input so we check for a link, not text
          page.has_link?(name, wait: 0)
        end
      end
    end
  end
end
