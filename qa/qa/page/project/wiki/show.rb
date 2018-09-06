# frozen_string_literal: true

module QA
  module Page
    module Project
      module Wiki
        class Show < Page::Base
          include Page::Component::ClonePanel

          view 'app/views/projects/wikis/pages.html.haml' do
            element :clone_repository_link, 'Clone repository'
          end

          def go_to_clone_repository
            click_on 'Clone repository'
          end
        end
      end
    end
  end
end
