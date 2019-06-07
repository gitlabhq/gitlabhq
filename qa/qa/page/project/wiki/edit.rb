# frozen_string_literal: true

module QA
  module Page
    module Project
      module Wiki
        class Edit < Page::Base
          view 'app/views/projects/wikis/_main_links.html.haml' do
            element :new_page_link, 'New page' # rubocop:disable QA/ElementWithPattern
            element :page_history_link, 'Page history' # rubocop:disable QA/ElementWithPattern
            element :edit_page_link, 'Edit' # rubocop:disable QA/ElementWithPattern
          end

          def click_edit
            click_on 'Edit'
          end
        end
      end
    end
  end
end
