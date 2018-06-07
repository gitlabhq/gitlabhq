module QA
  module Page
    module Project
      module Wiki
        class Pages < Page::Base
          view 'app/views/projects/wikis/pages.html.haml' do
          end

          def clone_repository
            click_on 'Clone repository'
          end

        end
      end
    end
  end
end
