# frozen_string_literal: true

module QA
  module Page
    module Project
      module PipelineEditor
        class Show < QA::Page::Base
          view 'app/assets/javascripts/ci/pipeline_editor/pipeline_editor_app.vue' do
            element :pipeline_editor_app, required: true
          end

          view 'app/assets/javascripts/ci/pipeline_editor/components/file_nav/branch_switcher.vue' do
            element :branch_selector_button, required: true
            element :branch_menu_item_button
            element :branch_menu_container
          end

          view 'app/assets/javascripts/ci/pipeline_editor/components/commit/commit_form.vue' do
            element :source_branch_field, required: true
          end

          view 'app/assets/javascripts/ci/pipeline_editor/components/editor/ci_editor_header.vue' do
            element :drawer_toggle, required: true
            element :template_repo_link, required: true
          end

          view 'app/assets/javascripts/vue_shared/components/source_editor.vue' do
            element :source_editor_container, required: true
          end

          view 'app/assets/javascripts/ci/pipeline_editor/components/header/pipeline_status.vue' do
            element :pipeline_id_content
          end

          view 'app/assets/javascripts/ci/pipeline_editor/components/commit/commit_form.vue' do
            element :commit_changes_button
            element :new_mr_checkbox
          end

          view 'app/assets/javascripts/ci/pipeline_editor/components/header/validation_segment.vue' do
            element :validation_message_content
          end

          view 'app/assets/javascripts/pipelines/components/pipeline_graph/pipeline_graph.vue' do
            element :stage_container
            element :job_container
          end

          view 'app/assets/javascripts/ci/pipeline_editor/components/pipeline_editor_tabs.vue' do
            element :file_editor_container
          end

          view 'app/assets/javascripts/ci/pipeline_editor/components/popovers/file_tree_popover.vue' do
            element :file_tree_popover
          end

          view 'app/assets/javascripts/ci/pipeline_editor/components/validate/ci_validate.vue' do
            element :simulate_pipeline_button
          end

          def initialize
            wait_for_requests(skip_finished_loading_check: true)
            dismiss_file_tree_popover

            super
          end

          def dismiss_file_tree_popover
            # clicking outside the popover will dismiss it
            click_element(:pipeline_editor_app)
          end

          def open_branch_selector_dropdown
            click_element(:branch_selector_button)
          end

          def select_branch_from_dropdown(branch_name)
            wait_for_animated_element(:branch_menu_container)
            click_element(:branch_menu_item_button, text: branch_name)

            wait_for_requests
          end

          def source_branch_name
            find_element(:source_branch_field).value
          end

          def editing_content
            find_element(:source_editor_container).text
          end

          def write_to_editor(text)
            find_element(:source_editor_container).fill_in(with: text)

            wait_for_requests
          end

          def submit_changes
            wait_until(reload: false) { !find_element(:commit_changes_button).disabled? }
            click_element(:commit_changes_button)

            wait_for_requests
          end

          def set_source_branch(name)
            find_element(:source_branch_field).fill_in(with: name)
          end

          def current_branch
            find_element(:branch_selector_button).text
          end

          def pipeline_id
            find_element(:pipeline_id_content).text.delete!('#').to_i
          end

          def ci_syntax_validate_message
            find_element(:validation_message_content).text
          end

          def go_to_visualize_tab
            go_to_tab('Visualize')
          end

          def go_to_full_configuration_tab
            go_to_tab('Full configuration')
          end

          def go_to_validate_tab
            go_to_tab('Validate')
          end

          def has_source_editor?
            has_element?(:source_editor_container)
          end

          def has_stage?(name)
            all_elements(:stage_container, minimum: 1).any? { |item| item.text.match(/#{name}/i) }
          end

          def has_job?(name)
            all_elements(:job_container, minimum: 1).any? { |item| item.text.match(/#{name}/i) }
          end

          def has_no_alert?
            has_no_css?('.gl-alert-body')
          end

          def tab_alert_message
            within_element(:file_editor_container) do
              find('.gl-alert-body').text
            end
          end

          def tab_alert_title
            within_element(:file_editor_container) do
              find('.gl-alert-title').text
            end
          end

          def has_new_mr_checkbox?
            has_element?(:new_mr_checkbox, visible: true)
          end

          def has_no_new_mr_checkbox?
            has_no_element?(:new_mr_checkbox, visible: true)
          end

          def select_new_mr_checkbox
            check_element(:new_mr_checkbox, true)
          end

          def simulate_pipeline
            click_element(:simulate_pipeline_button)
          end

          private

          def go_to_tab(name)
            within_element(:file_editor_container) do
              find('.nav-item', text: name).click
            end

            wait_for_requests
          end
        end
      end
    end
  end
end

QA::Page::Project::PipelineEditor::Show.prepend_mod_with('Page::Project::PipelineEditor::Show', namespace: QA)
