# frozen_string_literal: true

module QA
  module Page
    module Dashboard
      class Todos < Page::Base
        include Page::Component::Snippet

        view 'app/assets/javascripts/todos/components/todos_app.vue' do
          element 'todos-list-container', required: true
        end

        view 'app/assets/javascripts/todos/components/todos_filter_bar.vue' do
          element 'todos-filtered-search-container'
        end

        view 'app/assets/javascripts/todos/components/todo_item_body.vue' do
          element 'todo-item-container'
          element 'todo-action-name-content'
          element 'todo-author-name-content'
        end

        def has_todo_list?
          has_element?('todo-item-container')
        end

        def has_no_todo_list?
          has_no_element?('todo-item-container')
        end

        def filter_todos_by_group(group)
          within_element 'todos-filtered-search-container' do
            click_element 'filtered-search-term-input'
            click_element('filtered-search-suggestion', text: 'Group')
            fill_element('filtered-search-token-segment-input', group.path)
            click_element('filtered-search-suggestion', text: group.path)
            click_element 'search-button'
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
          within_element('todo-item-list-container') do
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
