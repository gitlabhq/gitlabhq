module QA
  module Page
    module Project
      module Settings
        class SecretVariables < Page::Base
          include Common

          view 'app/views/ci/variables/_variable_row.html.haml' do
            element :variable_key, '.js-ci-variable-input-key'
            element :variable_value, '.js-ci-variable-input-value'
          end

          view 'app/views/ci/variables/_index.html.haml' do
            element :save_variables, '.js-secret-variables-save-button'
          end

          def fill_variable_key(key)
            page.within('.js-ci-variable-list-section .js-row:nth-child(1)') do
              page.find('.js-ci-variable-input-key').set(key)
            end
          end

          def fill_variable_value(value)
            page.within('.js-ci-variable-list-section .js-row:nth-child(1)') do
              page.find('.js-ci-variable-input-value').set(value)
            end
          end

          def save_variables
            click_button('Save variables')
          end

          def variable_key
            page.within('.js-ci-variable-list-section .js-row:nth-child(1)') do
              page.find('.js-ci-variable-input-key').value
            end
          end

          def variable_value
            page.within('.js-ci-variable-list-section .js-row:nth-child(1)') do
              page.find('.js-ci-variable-input-value').value
            end
          end
        end
      end
    end
  end
end
