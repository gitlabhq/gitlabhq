# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class CiVariables < Page::Base
          include Common

          view 'app/views/ci/variables/_variable_row.html.haml' do
            element :variable_row, '.ci-variable-row-body' # rubocop:disable QA/ElementWithPattern
            element :variable_key, '.qa-ci-variable-input-key' # rubocop:disable QA/ElementWithPattern
            element :variable_value, '.qa-ci-variable-input-value' # rubocop:disable QA/ElementWithPattern
            element :variable_masked
          end

          view 'app/views/ci/variables/_index.html.haml' do
            element :save_variables, '.js-ci-variables-save-button' # rubocop:disable QA/ElementWithPattern
            element :reveal_values, '.js-secret-value-reveal-button' # rubocop:disable QA/ElementWithPattern
          end

          def fill_variable(key, value, masked)
            keys = all_elements(:ci_variable_input_key, minimum: 1)
            index = keys.size - 1

            # After we fill the key, JS would generate another field so
            # we need to use the same index to find the corresponding one.
            keys[index].set(key)
            node = all_elements(:ci_variable_input_value, count: keys.size + 1)[index]

            # Simply run `node.set(value)` is too slow for long text here,
            # so we need to run JavaScript directly to set the value.
            # The code was inspired from:
            # https://github.com/teamcapybara/capybara/blob/679548cea10773d45e32808f4d964377cfe5e892/lib/capybara/selenium/node.rb#L217
            execute_script("arguments[0].value = #{value.to_json}", node)

            masked_node = all_elements(:variable_masked, count: keys.size + 1)[index]
            toggle_masked(masked_node, masked)
          end

          def save_variables
            find('.js-ci-variables-save-button').click
          end

          def reveal_variables
            find('.js-secret-value-reveal-button').click
          end

          def variable_value(key)
            within('.ci-variable-row-body', text: key) do
              find('.qa-ci-variable-input-value').value
            end
          end

          private

          def toggle_masked(masked_node, masked)
            wait(reload: false) do
              masked_node.click

              masked ? masked_enabled?(masked_node) : masked_disabled?(masked_node)
            end
          end

          def masked_enabled?(masked_node)
            masked_node[:class].include?('is-checked')
          end

          def masked_disabled?(masked_node)
            !masked_enabled?(masked_node)
          end
        end
      end
    end
  end
end
