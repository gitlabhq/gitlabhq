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
