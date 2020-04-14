# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class CiVariables < Page::Base
          include Common

          view 'app/assets/javascripts/ci_variable_list/components/ci_variable_modal.vue' do
            element :ci_variable_key_field
            element :ci_variable_value_field
            element :ci_variable_masked_checkbox
            element :ci_variable_save_button
            element :ci_variable_delete_button
          end

          view 'app/assets/javascripts/ci_variable_list/components/ci_variable_table.vue' do
            element :ci_variable_table_content
            element :add_ci_variable_button
            element :edit_ci_variable_button
            element :reveal_ci_variable_value_button
          end

          def fill_variable(key, value, masked)
            fill_element :ci_variable_key_field, key
            fill_element :ci_variable_value_field, value
            click_ci_variable_save_button
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

          def click_reveal_ci_variable_value_button
            click_element :reveal_ci_variable_value_button
          end

          def click_ci_variable_delete_button
            click_element :ci_variable_delete_button
          end
        end
      end
    end
  end
end
