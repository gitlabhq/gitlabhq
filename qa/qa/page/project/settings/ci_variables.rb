# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class CiVariables < Page::Base
          include QA::Page::Settings::Common

          view 'app/assets/javascripts/ci/ci_variable_list/components/ci_variable_drawer.vue' do
            element 'ci-variable-key'
            element 'ci-variable-value'
            element 'ci-variable-confirm-button'
          end

          def fill_variable(key, value, masked = false)
            within_element('ci-variable-key') { find('input').set key }
            fill_element 'ci-variable-value', value
            click_ci_variable_save_button

            wait_until(reload: false) do
              within_element('ci-variable-table') { has_element?('edit-ci-variable-button') }
            end
          end

          def click_add_variable
            click_element 'add-ci-variable-button'
          end

          def click_edit_ci_variable
            within_element('ci-variable-table') do
              click_element 'edit-ci-variable-button'
            end
          end

          def click_ci_variable_save_button
            click_element 'ci-variable-confirm-button'
          end
        end
      end
    end
  end
end
