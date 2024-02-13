# frozen_string_literal: true

module QA
  module Page
    module Project
      module Pipeline
        class New < QA::Page::Base
          view 'app/assets/javascripts/ci/pipeline_new/components/pipeline_new_form.vue' do
            element 'run-pipeline-button', required: true
            element 'ci-variable-row-container'
            element 'pipeline-form-ci-variable-key-field'
            element 'pipeline-form-ci-variable-value-field'
            element 'pipeline-form-ci-variable-value-dropdown'
          end

          def click_run_pipeline_button
            click_element('run-pipeline-button', Page::Project::Pipeline::Show)
          end

          def click_variable_dropdown
            return unless has_variable_dropdown?

            click_element('pipeline-form-ci-variable-value-dropdown')
          end

          def configure_variable(key: nil, value: 'foo', row_index: 0)
            within_element_by_index('ci-variable-row-container', row_index) do
              fill_element('pipeline-form-ci-variable-key-field', key) unless key.nil?
              fill_element('pipeline-form-ci-variable-value-field', value)
            end
          end

          def has_variable_dropdown?
            has_element?('pipeline-form-ci-variable-value-dropdown')
          end

          def variable_dropdown
            return unless has_variable_dropdown?

            find_element('pipeline-form-ci-variable-value-dropdown')
          end

          def variable_dropdown_item_with_index(index)
            return unless has_variable_dropdown?

            within_element_by_index('.gl-new-dropdown-item', index) do
              find('.gl-new-dropdown-item-text-wrapper')
            end
          end
        end
      end
    end
  end
end
