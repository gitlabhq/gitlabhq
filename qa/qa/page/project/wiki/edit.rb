module QA
  module Page
    module Project
      module Wiki
        class Edit < Page::Base
          view 'app/views/projects/wikis/_main_links.html.haml' do
            element :new_page_link, 'New page'
            element :page_history_link, 'Page history'
            element :edit_page_link, 'Edit'
          end

          def go_to_new_page
            click_on 'New page'
          end

          def got_to_view_history_page
            click_on 'Page history'
          end

          def go_to_edit_page
            click_on 'Edit'
          end
        end
      end
    end
  end
end
