# frozen_string_literal: true

module QA
  module Page
    module Component
      module NamespaceSelect
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view "app/assets/javascripts/vue_shared/components/namespace_select/namespace_select.vue" do
            element :namespaces_list
            element :namespaces_list_groups
            element :namespaces_list_item
          end
        end

        def select_namespace(item)
          click_element :namespaces_list

          within_element(:namespaces_list) do
            find_element(:namespaces_list_item, text: item).click
          end
        end
      end
    end
  end
end
