# frozen_string_literal: true

module QA
  module Page
    module Project
      module PipelineEditor
        class Show < QA::Page::Base
          view 'app/assets/javascripts/pipeline_editor/components/file_nav/branch_switcher.vue' do
            element :branch_selector_button, require: true
            element :branch_menu_item_button
            element :branch_menu_container
          end

          view 'app/assets/javascripts/pipeline_editor/components/commit/commit_form.vue' do
            element :target_branch_field, require: true
          end

          view 'app/assets/javascripts/pipeline_editor/components/drawer/pipeline_editor_drawer.vue' do
            element :toggle_sidebar_collapse_button
            element :drawer_content
          end

          view 'app/assets/javascripts/vue_shared/components/source_editor.vue' do
            element :source_editor_container, require: true
          end

          def initialize
            super

            wait_for_requests
            close_toggle_sidebar
          end

          def open_branch_selector_dropdown
            click_element(:branch_selector_button)
          end

          def select_branch_from_dropdown(branch_name)
            wait_for_animated_element(:branch_menu_container)
            click_element(:branch_menu_item_button, text: branch_name)

            wait_for_requests
          end

          def target_branch_name
            find_element(:target_branch_field).value
          end

          def editing_content
            find_element(:source_editor_container).text
          end

          private

          # If the page thinks user has never opened pipeline editor before
          # It will expand pipeline editor sidebar by default
          # Collapse the sidebar if it is expanded
          def close_toggle_sidebar
            return unless has_element?(:drawer_content)

            click_element(:toggle_sidebar_collapse_button)
          end
        end
      end
    end
  end
end
