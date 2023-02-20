# frozen_string_literal: true

module QA
  module Page
    module Dashboard
      class Todos < Page::Base
        include Page::Component::Snippet

        view 'app/views/dashboard/todos/index.html.haml' do
          element :todos_list_container, required: true
          element :group_dropdown
        end

        view 'app/views/dashboard/todos/_todo.html.haml' do
          element :todo_item_container
          element :todo_action_name_content
          element :todo_target_title_content
          element :todo_author_name_content
        end

        view 'app/helpers/dropdowns_helper.rb' do
          element :dropdown_input_field
          element :dropdown_list_content
        end

        def has_todo_list?
          has_element?(:todo_item_container)
        end

        def has_no_todo_list?
          has_no_element?(:todo_item_container)
        end

        def filter_todos_by_group(group)
          click_element :group_dropdown

          fill_element(:dropdown_input_field, group.path)

          within_element(:dropdown_list_content) do
            click_on group.path
          end

          wait_for_requests
        end

        def has_latest_todo_with_author?(author:, action:)
          content = { selector: :todo_author_name_content, text: author }
          has_latest_todo_with_content?(action, **content)
        end

        def has_latest_todo_with_title?(title:, action:)
          content = { selector: :todo_target_title_content, text: title }
          has_latest_todo_with_content?(action, **content)
        end

        def click_todo_with_content(content)
          click_element(:todo_item_container, text: content)
        end

        private

        def has_latest_todo_with_content?(action, **kwargs)
          within_element(:todos_list_container) do
            within_element_by_index(:todo_item_container, 0) do
              has_element?(:todo_action_name_content, text: action) &&
                has_element?(kwargs[:selector], text: kwargs[:text])
            end
          end
        end
      end
    end
  end
end
