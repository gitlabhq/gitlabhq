module QA
  module Page
    module Project
      module Wiki
        class MainLinks < Page::Base
          view 'app/views/projects/wikis/_main_links.html.haml' do
          end

          def create_new_page
            click_on 'New page'
          end

          def view_history
            click_on 'Page history'
          end

          def edit_page
            click_on 'Edit'
          end

        end
      end
    end
  end
end
