# frozen_string_literal: true

module QA
  module Page
    module Project
      module Fork
        class New < Page::Base
          view 'app/views/projects/forks/_fork_button.html.haml' do
            element :fork_namespace_button
          end

          view 'app/assets/javascripts/pages/projects/forks/new/components/fork_groups_list.vue' do
            element :fork_groups_list_search_field
          end

          def choose_namespace(namespace = Runtime::Namespace.path)
            click_element(:fork_namespace_button, name: namespace)
          end

          def search_for_group(group_name)
            find_element(:fork_groups_list_search_field).set(group_name)
          end
        end
      end
    end
  end
end
