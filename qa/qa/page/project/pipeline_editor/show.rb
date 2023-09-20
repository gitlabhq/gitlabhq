# frozen_string_literal: true

module QA
  module Page
    module Project
      module PipelineEditor
        class Show < QA::Page::Base
          view 'app/assets/javascripts/vue_shared/components/source_editor.vue' do
            element 'source-editor-container', required: true
          end

          view 'app/assets/javascripts/ci/pipeline_editor/components/commit/commit_form.vue' do
            element 'source-branch-field', required: true
            element 'commit-changes-button'
            element 'new-mr-checkbox'
          end

          view 'app/assets/javascripts/ci/pipeline_editor/components/pipeline_editor_tabs.vue' do
            element 'file-editor-container', required: true
          end

          def initialize
            wait_for_requests(skip_finished_loading_check: true)
            dismiss_file_tree_popover

            super
          end

          def dismiss_file_tree_popover
            # clicking outside the popover will dismiss it
            click_element('source-editor-container')
          end

          def write_to_editor(text)
            find_element('source-editor-container').fill_in(with: text)

            wait_for_requests
          end

          def submit_changes
            wait_until(reload: false) { !find_element('commit-changes-button').disabled? }
            click_element('commit-changes-button')

            wait_for_requests
          end

          def set_source_branch(name)
            find_element('source-branch-field').fill_in(with: name)
          end

          def select_new_mr_checkbox
            check_element('new-mr-checkbox', true)
          end
        end
      end
    end
  end
end
