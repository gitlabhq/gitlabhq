# frozen_string_literal: true

module QA
  module Page
    module Component
      module ContentEditor
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/assets/javascripts/content_editor/components/content_editor.vue' do
            element :content_editor_container
          end

          base.view 'app/assets/javascripts/content_editor/components/toolbar_text_style_dropdown.vue' do
            element :text_style_dropdown
          end

          base.view 'app/assets/javascripts/content_editor/components/toolbar_attachment_button.vue' do
            element :file_upload_field
          end

          base.view 'app/assets/javascripts/vue_shared/components/markdown/markdown_editor.vue' do
            element :markdown_editor_form_field
          end
        end

        def add_heading(heading, text)
          within_element(:content_editor_container) do
            text_area.set(text)
            # wait for text style option to become active after typing
            has_active_element?(:text_style_dropdown, wait: 1)
            click_element(:text_style_dropdown)
            find_element(:text_style_dropdown).find('li', text: heading).click
          end
        end

        def upload_image(image_path)
          within_element(:content_editor_container) do
            # add image on a new line
            text_area.send_keys(:return)
            find_element(:file_upload_field, visible: false).send_keys(image_path)
          end

          QA::Support::Retrier.retry_on_exception do
            source = find_element(:markdown_editor_form_field, visible: false)
            source.value =~ %r{uploads/.*#{::File.basename(image_path)}}
          end
        end

        private

        def text_area
          find('[contenteditable="true"]', visible: false)
        end
      end
    end
  end
end
