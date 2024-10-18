# frozen_string_literal: true

module QA
  module Page
    module Project
      module Fork
        class New < Page::Base
          include ::QA::Page::Component::Dropdown

          view 'app/assets/javascripts/pages/projects/forks/new/components/fork_form.vue' do
            element 'fork-project-button'
            element 'fork-privacy-button'
          end

          view 'app/assets/javascripts/pages/projects/forks/new/components/project_namespace.vue' do
            element 'select-namespace-dropdown'
          end

          def fork_project(namespace)
            choose_namespace(namespace)
            click_element('fork-privacy-button', privacy_level: 'public')
            click_element('fork-project-button')
          end

          def get_list_of_namespaces
            click_element('select-namespace-dropdown')
            all_items
          end

          def choose_namespace(namespace)
            retry_on_exception do
              click_element('select-namespace-dropdown')
              search_and_select(namespace)
            end
          end
        end
      end
    end
  end
end
