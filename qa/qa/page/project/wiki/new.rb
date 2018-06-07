module QA
  module Page
    module Project
      module Wiki
        class New < Page::Base
          view 'app/views/projects/wikis/_new.html.haml' do
          end

          def add_title(title)
            fill_in 'wiki_title', with: title
          end

          def add_content(content)
            fill_in 'wiki_content', with: content
          end

          def add_message(message)
            fill_in 'wiki_message', with: message
          end

          def create_new_page
            click_on 'Create page'
          end
        end
      end
    end
  end
end
