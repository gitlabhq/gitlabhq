# frozen_string_literal: true

module QA
  module Page
    module Project
      module Wiki
        class Show < Page::Base
          include Component::LazyLoader

          view 'app/views/shared/wikis/_sidebar.html.haml' do
            element :clone_repository_link
          end

          view 'app/views/shared/wikis/show.html.haml' do
            element :wiki_page_title
            element :wiki_page_content
          end

          view 'app/views/shared/wikis/_main_links.html.haml' do
            element :new_page_button
            element :page_history_button
            element :edit_page_button
          end

          view 'app/views/shared/empty_states/_wikis.html.haml' do
            element :create_first_page_link
          end

          view 'app/views/shared/empty_states/_wikis_layout.html.haml' do
            element :svg_content
          end

          def click_create_your_first_page
            # The svg takes a fraction of a second to load after which the
            # "Create your first page" button shifts up a bit. This can cause
            # webdriver to miss the hit so we wait for the svg to load before
            # clicking the button.
            within_element(:svg_content) do
              has_element? :js_lazy_loaded
            end

            click_element :create_first_page_link
          end

          def click_new_page
            click_element(:new_page_button)
          end

          def click_page_history
            click_element(:page_history_button)
          end

          def click_edit
            click_element(:edit_page_button)
          end

          def click_clone_repository
            click_element(:clone_repository_link)
          end

          def wiki_text
            find_element(:wiki_page_content).text
          end

          def has_title?(title)
            has_element?(:wiki_page_title, title)
          end

          def has_content?(content)
            has_element?(:wiki_page_content, content)
          end
        end
      end
    end
  end
end

QA::Page::Project::Wiki::Show.prepend_if_ee('QA::EE::Page::Project::Wiki::Show')
