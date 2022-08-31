# frozen_string_literal: true

module QA
  module Page
    module Project
      module Fork
        class New < Page::Base
          view 'app/assets/javascripts/pages/projects/forks/new/components/fork_form.vue' do
            element :fork_project_button
            element :fork_privacy_button
          end

          view 'app/assets/javascripts/pages/projects/forks/new/components/project_namespace.vue' do
            element :select_namespace_dropdown
            element :select_namespace_dropdown_item
            element :select_namespace_dropdown_search_field
            element :select_namespace_dropdown_item
          end

          def fork_project(namespace = Runtime::Namespace.path)
            choose_namespace(namespace)
            click_element(:fork_privacy_button, privacy_level: 'public')
            click_element(:fork_project_button)
          end

          def get_list_of_namespaces
            click_element(:select_namespace_dropdown)
            wait_until(reload: false) do
              has_element?(:select_namespace_dropdown_item)
            end
            all_elements(:select_namespace_dropdown_item, minimum: 1).map(&:text)
          end

          def choose_namespace(namespace)
            retry_on_exception do
              click_element(:select_namespace_dropdown)
              fill_element(:select_namespace_dropdown_search_field, namespace)
              wait_until(reload: false) do
                has_element?(:select_namespace_dropdown_item, text: namespace)
              end
              click_button(namespace)
            end
          end
        end
      end
    end
  end
end
