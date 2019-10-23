# frozen_string_literal: true

module QA
  module Page
    module Project
      module Wiki
        class Show < Page::Base
          include Page::Component::LegacyClonePanel

          view 'app/views/shared/wiki/_page_listing.html.haml' do
            element :clone_repository_link, 'Clone repository' # rubocop:disable QA/ElementWithPattern
          end

          view 'app/views/projects/wiki_pages/show.html.haml' do
            element :wiki_page_content
          end

          def click_clone_repository
            click_on 'Clone repository'
          end

          def wiki_text
            find_element(:wiki_page_content).text
          end
        end
      end
    end
  end
end

QA::Page::Project::Wiki::Show.prepend_if_ee('QA::EE::Page::Project::Wiki::Show')
