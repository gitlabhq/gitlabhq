# frozen_string_literal: true

module QA
  module Page
    module Component
      module DesignManagement
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.class_eval do
            view 'app/assets/javascripts/design_management/components/design_notes/design_discussion.vue' do
              element 'design-discussion-content'
            end

            view 'app/assets/javascripts/design_management/components/design_notes/design_note.vue' do
              element 'note-text'
            end

            view 'app/assets/javascripts/design_management/components/design_notes/design_reply_form.vue' do
              element 'note-textarea'
              element 'save-comment-button'
            end

            view 'app/assets/javascripts/design_management/components/design_overlay.vue' do
              element 'design-image-button'
            end

            view 'app/assets/javascripts/design_management/components/list/item.vue' do
              element 'design-file-name'
              element 'design-image'
              element 'design-status-icon'
            end

            view 'app/assets/javascripts/design_management/pages/index.vue' do
              element 'archive-button'
              element 'design-checkbox'
              element 'design-dropzone-content'
            end

            view 'app/assets/javascripts/design_management/components/delete_button.vue' do
              element 'confirm-archiving-button'
            end
          end
        end

        def add_annotation(note)
          click_element('design-image-button')
          fill_editor_element('note-textarea', note)
          has_active_element?('save-comment-button', wait: 0.5)
          click_element('save-comment-button')

          # It takes a moment for the annotation to be saved.
          # We'll check for the annotation in a test, but here we'll at least
          # wait for the "Save comment" button to disappear
          saved = has_no_element?('save-comment-button')
          return if saved

          raise RSpec::Expectations::ExpectationNotMetError, %q(There was a problem while adding the annotation)
        end

        def add_design(design_file_path)
          # `attach_file` doesn't seem able to find element via data attributes.
          # It accepts a `class:` option, but that only works for class attributes
          # It doesn't work as a CSS selector.
          # So instead we use the name attribute as a locator
          within_element('design-dropzone-content') do
            page.attach_file("upload_file", design_file_path, make_visible: { display: 'block' })
          end

          filename = ::File.basename(design_file_path)

          wait_until(reload: false, sleep_interval: 1, message: "Design upload") do
            image = find_element('design-image', filename: filename).find('img')

            has_element?('design-file-name', text: filename) && image["complete"] && image["naturalWidth"].to_i > 0
          end
        end

        def update_design(filename)
          filepath = Runtime::Path.fixture('designs', 'update', filename)
          add_design(filepath)
        end

        def click_design(filename)
          click_element('design-file-name', text: filename)
        end

        def select_design(filename)
          click_element('design-checkbox', design: filename)
        end

        def archive_selected_designs
          click_element('archive-button')
          click_element('confirm-archiving-button')
        end

        def has_annotation?(note)
          within_element_by_index('design-discussion-content', 0) do
            has_element?('note-text', text: note)
          end
        end

        def has_design?(filename)
          has_element?('design-file-name', text: filename)
        end

        def has_no_design?(filename)
          has_no_element?('design-file-name', text: filename)
        end

        def has_created_icon?
          has_element?('design-status-icon', status: 'file-addition-solid')
        end

        def has_modified_icon?
          has_element?('design-status-icon', status: 'file-modified-solid')
        end
      end
    end
  end
end
