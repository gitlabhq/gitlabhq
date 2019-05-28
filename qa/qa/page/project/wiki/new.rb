# frozen_string_literal: true

module QA
  module Page
    module Project
      module Wiki
        class New < Page::Base
          include Component::LazyLoader

          view 'app/views/projects/wikis/_form.html.haml' do
            element :wiki_title_textbox
            element :wiki_content_textarea
            element :wiki_message_textbox
            element :save_changes_button
            element :create_page_button
          end

          view 'app/views/shared/empty_states/_wikis.html.haml' do
            element :create_first_page_link
          end

          view 'app/views/shared/empty_states/_wikis_layout.html.haml' do
            element :svg_content
          end

          def click_create_your_first_page_button
            # The svg takes a fraction of a second to load after which the
            # "Create your first page" button shifts up a bit. This can cause
            # webdriver to miss the hit so we wait for the svg to load before
            # clicking the button.
            within_element(:svg_content) do
              has_element? :js_lazy_loaded
            end

            click_element :create_first_page_link
          end

          def set_title(title)
            fill_element :wiki_title_textbox, title
          end

          def set_content(content)
            fill_element :wiki_content_textarea, content
          end

          def set_message(message)
            fill_element :wiki_message_textbox, message
          end

          def save_changes
            click_element :save_changes_button
          end

          def create_new_page
            click_element :create_page_button
          end
        end
      end
    end
  end
end
