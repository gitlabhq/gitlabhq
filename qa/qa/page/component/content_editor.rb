# frozen_string_literal: true

module QA
  module Page
    module Component
      module ContentEditor
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/assets/javascripts/content_editor/components/content_editor.vue' do
            element 'content-editor'
          end

          base.view 'app/assets/javascripts/content_editor/components/formatting_toolbar.vue' do
            element 'text-styles'
          end

          base.view 'app/assets/javascripts/content_editor/components/toolbar_attachment_button.vue' do
            element 'file-upload-field'
          end

          base.view 'app/assets/javascripts/vue_shared/components/markdown/markdown_editor.vue' do
            element 'markdown-editor-form-field'
          end
        end

        def add_heading(heading, text)
          within_element('content-editor') do
            text_area.set(text)
            within_element('formatting-toolbar') do
              click_element('text-styles')
              find_element('.gl-new-dropdown-contents li', text: heading).click
            end
          end
        end

        def upload_image(image_path)
          within_element('content-editor') do
            # add image on a new line
            text_area.send_keys(:return)
            find_element('file-upload-field', visible: false).send_keys(image_path)
          end

          QA::Support::Retrier.retry_on_exception do
            source = find_element('markdown-editor-form-field', visible: false)
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
