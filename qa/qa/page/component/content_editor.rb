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
            element :text_style_menu_item
          end

          base.view 'app/assets/javascripts/content_editor/components/toolbar_image_button.vue' do
            element :file_upload_field
          end
        end

        def add_heading(heading, text)
          within_element(:content_editor_container) do
            text_area.set(text)
            # wait for text style option to become active after typing
            has_active_element?(:text_style_dropdown, wait: 1)
            click_element(:text_style_dropdown)
            within_element(:text_style_dropdown) do
              click_element(:text_style_menu_item, text_style: heading)
            end
          end
        end

        def upload_image(image_path)
          within_element(:content_editor_container) do
            # add image on a new line
            text_area.send_keys(:return)
            find_element(:file_upload_field, visible: false).send_keys(image_path)
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
