module QA
  module Page
    module Project
      module Settings
        class SecretVariables < Page::Base
          include Common

          view 'app/views/ci/variables/_variable_row.html.haml' do
            element :variable_row, '.ci-variable-row-body'
            element :variable_key, '.js-ci-variable-input-key'
            element :variable_value, '.js-ci-variable-input-value'
            element :key_placeholder, 'Input variable key'
            element :value_placeholder, 'Input variable value'
          end

          view 'app/views/ci/variables/_index.html.haml' do
            element :save_variables, '.js-secret-variables-save-button'
            element :reveal_values, '.js-secret-value-reveal-button'
          end

          def fill_variable_key(key)
            fill_in('Input variable key', with: key, match: :first)
          end

          def fill_variable_value(value)
            fill_in('Input variable value', with: value, match: :first)
          end

          def save_variables
            find('.js-secret-variables-save-button').click
          end

          def reveal_variables
            find('.js-secret-value-reveal-button').click
          end

          def variable_value(key)
            within('.ci-variable-row-body', text: key) do
              find('.js-ci-variable-input-value').value
            end
          end
        end
      end
    end
  end
end
