# frozen_string_literal: true

module QA
  module Page
    module File
      module Shared
        module Editor
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.view 'app/views/projects/blob/_editor.html.haml' do
              element 'source-editor-preview-container'
            end

            base.view 'app/assets/javascripts/repository/components/commit_changes_modal.vue' do
              element 'commit-change-modal'
            end

            base.view 'app/assets/javascripts/repository/components/commit_changes_modal.vue' do
              element 'commit-change-modal-commit-button'
            end

            base.view 'app/assets/javascripts/repository/pages/blob_edit_header.vue' do
              element 'blob-edit-header-commit-button'
            end
          end

          def add_content(content)
            text_area.set content
          end

          def remove_content
            if page.driver.browser.capabilities.platform_name.include? "mac"
              text_area.send_keys([:command, 'a'], :backspace)
            else
              text_area.send_keys([:control, 'a'], :backspace)
            end
          end

          def click_commit_changes_in_header
            click_element('blob-edit-header-commit-button')
          end

          def commit_changes_through_modal
            within_element 'commit-change-modal' do
              click_element('commit-change-modal-commit-button')
            end
          end

          def has_modal_commit_button?
            has_element?('commit-change-modal-commit-button')
          end

          private

          def text_area
            within_element 'source-editor-preview-container' do
              find('textarea', visible: false)
            end
          end
        end
      end
    end
  end
end
