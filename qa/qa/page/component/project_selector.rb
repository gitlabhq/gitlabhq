# frozen_string_literal: true

module QA
  module Page
    module Component
      module ProjectSelector
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/assets/javascripts/vue_shared/components/project_selector/project_selector.vue' do
            element :project_search_field
            element :project_list_item
          end
        end

        def fill_project_search_input(project_name)
          fill_element :project_search_field, project_name
        end

        def select_project
          wait_until(sleep_interval: 2, reload: false) do
            has_element? :project_list_item
          end
          click_element :project_list_item
        end
      end
    end
  end
end
