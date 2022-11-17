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

        def has_filtered_group?(name)
          # Filter and submit to reload the page and only retrieve the filtered results
          find_element(:groups_filter_field).set(name).send_keys(:return)

          # Since we submitted after filtering, the presence of
          # groups_list_tree_container means we have the complete filtered list
          # of groups
          has_element?(:groups_list_tree_container, wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)
          # If there are no groups we'll know immediately because we filtered the list
          if page.has_text?('No groups or projects matched your search',
wait: 0) || page.has_text?('No groups matched your search', wait: 0)
            return false unless has_element?(:public_groups_tab)

            # Try for public groups
            click_element(:public_groups_tab)
            # Filter and submit to reload the page and only retrieve the filtered results
            find_element(:groups_filter_field).set(name).send_keys(:return)

            # Since we submitted after filtering, the presence of
            # groups_list_tree_container means we have the complete filtered list
            # of groups
            has_element?(:groups_list_tree_container, wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)

            return false if page.has_text?('No groups or projects matched your search',
wait: 0) || page.has_text?('No groups matched your search', wait: 0)
          end

          # The name will be present as filter input so we check for a link, not text
          page.has_link?(name, wait: 0)
        end
      end
    end
  end
end
