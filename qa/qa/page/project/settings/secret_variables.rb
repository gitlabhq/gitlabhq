module QA
  module Page
    module Project
      module Settings
        class SecretVariables < Page::Base
          include Common

          view 'app/views/ci/variables/_table.html.haml' do
            element :variable_key, '.variable-key'
            element :variable_value, '.variable-value'
          end

          view 'app/views/ci/variables/_index.html.haml' do
            element :add_new_variable, 'btn_text: "Add new variable"'
          end

          view 'app/assets/javascripts/behaviors/secret_values.js' do
            element :reveal_value, 'Reveal value'
            element :hide_value, 'Hide value'
          end

          def fill_variable_key(key)
            fill_in 'variable_key', with: key
          end

          def fill_variable_value(value)
            fill_in 'variable_value', with: value
          end

          def add_variable
            click_on 'Add new variable'
          end

          def variable_key
            page.find('.variable-key').text
          end

          def variable_value
            reveal_value do
              page.find('.variable-value').text
            end
          end

          private

          def reveal_value
            click_button('Reveal value')

            yield.tap do
              click_button('Hide value')
            end
          end
        end
      end
    end
  end
end
