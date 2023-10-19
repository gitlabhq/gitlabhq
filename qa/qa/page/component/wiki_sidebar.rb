# frozen_string_literal: true

module QA
  module Page
    module Component
      module WikiSidebar
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/views/shared/wikis/_sidebar.html.haml' do
            element 'clone-repository-link'
            element 'view-all-pages-button'
          end

          base.view 'app/views/shared/wikis/_sidebar_wiki_page.html.haml' do
            element 'wiki-page-link'
          end

          base.view 'app/views/shared/wikis/_wiki_directory.html.haml' do
            element 'wiki-directory-content'
            element 'wiki-dir-page-link'
          end
        end

        def click_clone_repository
          click_element('clone-repository-link')
        end

        def click_view_all_pages
          click_element('view-all-pages-button')
        end

        def click_page_link(page_title)
          click_element('wiki-page-link', page_name: page_title)
        end

        def has_page_listed?(page_title)
          has_element?('wiki-page-link', page_name: page_title)
        end

        def has_directory?(directory)
          has_element?('wiki-directory-content', text: directory)
        end

        def has_dir_page?(dir_page)
          has_element?('wiki-dir-page-link', page_name: dir_page)
        end
      end
    end
  end
end
