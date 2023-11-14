# frozen_string_literal: true

module QA
  module Page
    module Dashboard
      class Todos < Page::Base
        include Page::Component::Snippet

        view 'app/views/dashboard/todos/index.html.haml' do
          element 'todos-list-container', required: true
          element 'group-dropdown'
        end

        view 'app/views/dashboard/todos/_todo.html.haml' do
          element 'todo-item-container'
          element 'todo-action-name-content'
          element 'todo-author-name-content'
        end

        view 'app/helpers/dropdowns_helper.rb' do
          element 'dropdown-input-field'
          element 'dropdown-list-content'
        end

        def has_todo_list?
          has_element?('todo-item-container')
        end

        def has_no_todo_list?
          has_no_element?('todo-item-container')
        end

        def filter_todos_by_group(group)
          click_element 'group-dropdown'

          fill_element('dropdown-input-field', group.path)

          within_element('dropdown-list-content') do
            click_on group.path
          end

          wait_for_requests
        end

        def click_todo_with_content(content)
          click_element('todo-item-container', text: content)
        end

        def has_latest_todo_with_author?(author:, action:)
          content = { selector: 'todo-author-name-content', text: author }
          has_latest_todo_with_content?(action, **content)
        end

        private

        def has_latest_todo_with_content?(action, **kwargs)
          within_element('todos-list-container') do
            within_element_by_index('todo-item-container', 0) do
              has_element?('todo-action-name-content', text: action) &&
                has_element?(kwargs[:selector], text: kwargs[:text])
            end
          end
        end
      end
    end
  end
end
