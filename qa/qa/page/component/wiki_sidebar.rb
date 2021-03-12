# frozen_string_literal: true

module QA
  module Page
    module Component
      module WikiSidebar
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/views/shared/wikis/_sidebar.html.haml' do
            element :clone_repository_link
            element :view_all_pages_button
          end

          base.view 'app/views/shared/wikis/_sidebar_wiki_page.html.haml' do
            element :wiki_page_link
          end

          base.view 'app/views/shared/wikis/_wiki_directory.html.haml' do
            element :wiki_directory_content
          end
        end

        def click_clone_repository
          click_element(:clone_repository_link)
        end

        def click_view_all_pages
          click_element(:view_all_pages_button)
        end

        def click_page_link(page_title)
          click_element(:wiki_page_link, page_name: page_title)
        end

        def has_page_listed?(page_title)
          has_element?(:wiki_page_link, page_name: page_title)
        end

        def has_directory?(directory)
          has_element?(:wiki_directory_content, text: directory)
        end
      end
    end
  end
end
