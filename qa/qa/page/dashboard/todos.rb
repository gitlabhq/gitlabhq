# frozen_string_literal: true

module QA
  module Page
    module Dashboard
      class Todos < Page::Base
        include Page::Component::Snippet

        view 'app/views/dashboard/todos/index.html.haml' do
          element :todos_list_container, required: true
        end

        view 'app/views/dashboard/todos/_todo.html.haml' do
          element :todo_item_container
          element :todo_action_name_content
          element :todo_target_title_content
        end

        def has_todo_list?
          has_element? :todo_item_container
        end

        def has_latest_todo_item_with_content?(action, title)
          within_element(:todos_list_container) do
            within_element_by_index(:todo_item_container, 0) do
              has_element?(:todo_action_name_content, text: action) && has_element?(:todo_target_title_content, text: title)
            end
          end
        end
      end
    end
  end
end
