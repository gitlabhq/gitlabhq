# frozen_string_literal: true

module QA
  module Page
    module Component
      module NamespaceSelect
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view "app/assets/javascripts/groups_projects/components/transfer_locations.vue" do
            element :namespaces_list
            element :namespaces_list_groups
            element :namespaces_list_item
            element :namespaces_list_search
          end
        end

        def select_namespace(item)
          click_element :namespaces_list

          within_element(:namespaces_list) do
            fill_element(:namespaces_list_search, item)

            wait_for_requests

            # Click element by JS in case dropdown changes position mid-click
            # Workaround for issue https://gitlab.com/gitlab-org/gitlab/-/issues/381376
            namespace = find_element(:namespaces_list_item, text: item, visible: false)
            click_by_javascript(namespace)
          end
        end
      end
    end
  end
end
