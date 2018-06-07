module QA
  module Page
    module Project
      module Wiki
        class Empty < Page::Base
          view 'app/views/shared/empty_states/_wikis.html.haml' do
            element :create_link, 'Create your first page'
          end

          def create_wiki
            click_link 'Create your first page'
          end
        end
      end
    end
  end
end
