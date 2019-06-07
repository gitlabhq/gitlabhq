# frozen_string_literal: true

module QA
  module Page
    module Project
      module Wiki
        class Show < Page::Base
          include Page::Component::LegacyClonePanel

          view 'app/views/projects/wikis/pages.html.haml' do
            element :clone_repository_link, 'Clone repository' # rubocop:disable QA/ElementWithPattern
          end

          def click_clone_repository
            click_on 'Clone repository'
          end
        end
      end
    end
  end
end
