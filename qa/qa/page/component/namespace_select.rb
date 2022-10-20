# frozen_string_literal: true

module QA
  module Page
    module Component
      module NamespaceSelect
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view "app/assets/javascripts/vue_shared/components/namespace_select/namespace_select_deprecated.vue" do
            element :namespaces_list
            element :namespaces_list_groups
            element :namespaces_list_item
            element :namespaces_list_search
          end
        end

        def select_namespace(item)
          click_element :namespaces_list

          wait_for_requests

          within_element(:namespaces_list) do
            fill_element(:namespaces_list_search, item)

            wait_for_requests

            find_element(:namespaces_list_item, text: item).click
          end
        end
      end
    end
  end
end
