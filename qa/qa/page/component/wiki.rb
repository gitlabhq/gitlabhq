# frozen_string_literal: true

module QA
  module Page
    module Component
      module Wiki
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/views/shared/wikis/show.html.haml' do
            element 'wiki-page-title'
            element 'wiki-edit-button'
          end

          base.view 'app/views/shared/wikis/_wiki_content.html.haml' do
            element 'wiki-page-content'
          end

          base.view 'app/views/shared/wikis/_main_links.html.haml' do
            element 'new-page-button'
          end

          base.view 'app/views/shared/empty_states/_wikis.html.haml' do
            element 'create-first-page-link'
          end

          base.view 'app/views/shared/empty_states/_wikis_layout.html.haml' do
            element 'svg-content'
          end
        end

        def click_create_your_first_page
          # The svg takes a fraction of a second to load after which the
          # "Create your first page" button shifts up a bit. This can cause
          # webdriver to miss the hit so we wait for the svg to load before
          # clicking the button.
          within_element('svg-content') do
            has_element?('js-lazy-loaded-content')
          end

          click_element('create-first-page-link')
        end

        def click_new_page
          click_element('new-page-button')
        end

        def click_page_history
          click_element('wiki-more-dropdown')
          click_element('page-history-button')
        end

        def click_edit
          click_element('wiki-edit-button')
        end

        def has_title?(title)
          has_element?('wiki-page-title', title)
        end

        def has_content?(content)
          has_element?('wiki-page-content', content)
        end

        def has_no_content?(content)
          has_no_element?('wiki-page-content', content)
        end

        def has_no_page?
          has_element?('create-first-page-link')
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
