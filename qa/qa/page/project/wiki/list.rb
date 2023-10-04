# frozen_string_literal: true

module QA
  module Page
    module Project
      module Wiki
        class List < Base
          view 'app/views/shared/wikis/_pages_wiki_page.html.haml' do
            element 'wiki-page-link'
          end

          def click_page_link(page_title)
            click_element 'wiki-page-link', page_name: page_title
          end

          def has_page_listed?(page_title)
            has_element? 'wiki-page-link', page_name: page_title
          end
        end
      end
    end
  end
end
