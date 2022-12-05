# frozen_string_literal: true

module QA
  module Page
    module Project
      module PipelineEditor
        class New < QA::Page::Base
          view 'app/assets/javascripts/ci/pipeline_editor/components/ui/pipeline_editor_empty_state.vue' do
            element :create_new_ci_button, required: true
          end

          def create_new_ci
            click_element(:create_new_ci_button, Page::Project::PipelineEditor::Show)
          end
        end
      end
    end
  end
end
