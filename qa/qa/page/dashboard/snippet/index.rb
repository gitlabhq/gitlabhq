# frozen_string_literal: true

module QA
  module Page
    module Dashboard
      module Snippet
        class Index < Page::Base
          view 'app/views/layouts/header/_new_dropdown.haml' do
            element :new_menu_toggle
            element :global_new_snippet_link
          end

          def go_to_new_snippet_page
            click_element :new_menu_toggle
            click_element :global_new_snippet_link
          end
        end
      end
    end
  end
end
