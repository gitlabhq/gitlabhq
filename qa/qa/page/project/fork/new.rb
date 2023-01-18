# frozen_string_literal: true

module QA
  module Page
    module Project
      module Fork
        class New < Page::Base
          include ::QA::Page::Component::Dropdown

          view 'app/assets/javascripts/pages/projects/forks/new/components/fork_form.vue' do
            element :fork_project_button
            element :fork_privacy_button
          end

          view 'app/assets/javascripts/pages/projects/forks/new/components/project_namespace.vue' do
            element :select_namespace_dropdown
          end

          def fork_project(namespace = Runtime::Namespace.path)
            choose_namespace(namespace)
            click_element(:fork_privacy_button, privacy_level: 'public')
            click_element(:fork_project_button)
          end

          def get_list_of_namespaces
            click_element(:select_namespace_dropdown)
            all_items
          end

          def choose_namespace(namespace)
            retry_on_exception do
              click_element(:select_namespace_dropdown)
              search_and_select(namespace)
            end
          end
        end
      end
    end
  end
end
