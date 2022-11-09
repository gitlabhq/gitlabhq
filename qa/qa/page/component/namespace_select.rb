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

            click_element(:namespaces_list_item, text: item)
          end
        end
      end
    end
  end
end
