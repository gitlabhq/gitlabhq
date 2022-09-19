# frozen_string_literal: true

module QA
  module Page
    module Project
      module Pipeline
        class New < QA::Page::Base
          view 'app/assets/javascripts/pipeline_new/components/legacy_pipeline_new_form.vue' do
            element :run_pipeline_button, required: true
            element :ci_variable_row_container
            element :ci_variable_key_field
            element :ci_variable_value_field
          end

          def click_run_pipeline_button
            click_element(:run_pipeline_button, Page::Project::Pipeline::Show)
          end

          def configure_variable(key: nil, value: 'foo', row_index: 0)
            within_element_by_index(:ci_variable_row_container, row_index) do
              fill_element(:ci_variable_key_field, key) unless key.nil?
              fill_element(:ci_variable_value_field, value)
            end
          end
        end
      end
    end
  end
end
