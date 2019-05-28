# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Settings
        module Component
          class AccountAndLimit < Page::Base
            view 'app/views/admin/application_settings/_account_and_limit.html.haml' do
              element :receive_max_input_size_field
              element :save_changes_button
            end

            def set_max_file_size(size)
              fill_element :receive_max_input_size_field, size
            end

            def save_settings
              click_element :save_changes_button
            end
          end
        end
      end
    end
  end
end
