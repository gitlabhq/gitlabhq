# frozen_string_literal: true

module QA
  module Page
    module Component
      module Wiki
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/views/shared/wikis/show.html.haml' do
            element 'wiki-page-content-app'
          end

          base.view 'app/views/shared/wikis/_wiki_content.html.haml' do
            element 'wiki-page-content'
          end

          base.view 'app/views/shared/empty_states/_wikis.html.haml' do
            element 'wiki-empty-state'
          end
        end

        def click_create_your_first_page
          click_link 'Create your first page'
        end

        def click_new_page
          click_element('wiki-more-dropdown')
          click_element('page-new-button')
        end

        def click_page_history
          click_element('wiki-more-dropdown')
          click_element('page-history-button')
        end

        def click_edit
          click_element('wiki-edit-button')
        end

        def has_title?(title)
          has_element?('page-heading', title)
        end

        def has_content?(content)
          has_element?('wiki-page-content', content)
        end

        def has_no_content?(content)
          has_no_element?('wiki-page-content', content)
        end

        def has_no_page?
          has_css?('[data-testid="wiki-empty-state"]')
        end

        def has_heading?(heading_type, text)
          within_element('wiki-page-content') do
            has_css?(heading_type, text: text)
          end
        end

        def has_image?(image_file_name)
          within_element('wiki-page-content') do
            has_css?("img[src$='#{image_file_name}']")
          end
        end
      end
    end
  end
end
