# frozen_string_literal: true

module QA
  module Page
    module Project
      module Pipeline
        class New < QA::Page::Base
          view 'app/assets/javascripts/ci/pipeline_new/components/pipeline_new_form.vue' do
            element :run_pipeline_button, required: true
            element :ci_variable_row_container
            element :ci_variable_key_field
            element :ci_variable_value_field
            element :ci_variable_value_dropdown
            element :ci_variable_value_dropdown_item
          end

          def click_run_pipeline_button
            click_element(:run_pipeline_button, Page::Project::Pipeline::Show)
          end

          def click_variable_dropdown
            return unless has_variable_dropdown?

            click_element(:ci_variable_value_dropdown)
          end

          def configure_variable(key: nil, value: 'foo', row_index: 0)
            within_element_by_index(:ci_variable_row_container, row_index) do
              fill_element(:ci_variable_key_field, key) unless key.nil?
              fill_element(:ci_variable_value_field, value)
            end
          end

          def has_variable_dropdown?
            has_element?(:ci_variable_value_dropdown)
          end

          def variable_dropdown
            return unless has_variable_dropdown?

            find_element(:ci_variable_value_dropdown)
          end

          def variable_dropdown_item_with_index(index)
            return unless has_variable_dropdown?

            within_element_by_index(:ci_variable_value_dropdown_item, index) do
              find('p')
            end
          end
        end
      end
    end
  end
end
