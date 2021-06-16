# frozen_string_literal: true

module QA
  module Page
    module Dashboard
      module Snippet
        class Index < Page::Base
          view 'app/views/layouts/header/_new_dropdown.html.haml' do
            element :new_menu_toggle
          end

          view 'app/helpers/nav/new_dropdown_helper.rb' do
            element :global_new_snippet_link
          end

          view 'app/views/shared/snippets/_snippet.html.haml' do
            element :snippet_link
            element :snippet_visibility_content
            element :snippet_file_count_content
          end

          def go_to_new_snippet_page
            click_element :new_menu_toggle
            click_element :global_new_snippet_link
          end

          def has_snippet_title?(snippet_title)
            has_element?(:snippet_link, snippet_title: snippet_title)
          end

          def has_visibility_level?(snippet_title, visibility)
            within_element(:snippet_link, snippet_title: snippet_title) do
              has_element?(:snippet_visibility_content, snippet_visibility: visibility)
            end
          end

          def has_number_of_files?(snippet_title, number)
            within_element(:snippet_link, snippet_title: snippet_title) do
              has_element?(:snippet_file_count_content, snippet_files: number)
            end
          end
        end
      end
    end
  end
end
