# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class CiVariables < Page::Base
          include QA::Page::Settings::Common

          view 'app/assets/javascripts/ci/ci_variable_list/components/ci_variable_modal.vue' do
            element :ci_variable_key_field
            element :ci_variable_value_field
            element :ci_variable_save_button
          end

          def fill_variable(key, value, masked = false)
            within_element(:ci_variable_key_field) { find('input').set key }
            fill_element :ci_variable_value_field, value
            click_ci_variable_save_button

            wait_until(reload: false) do
              within_element(:ci_variable_table_content) { has_element?(:edit_ci_variable_button) }
            end
          end

          def click_add_variable
            click_element :add_ci_variable_button
          end

          def click_edit_ci_variable
            within_element(:ci_variable_table_content) do
              click_element :edit_ci_variable_button
            end
          end

          def click_ci_variable_save_button
            click_element :ci_variable_save_button
          end
        end
      end
    end
  end
end
