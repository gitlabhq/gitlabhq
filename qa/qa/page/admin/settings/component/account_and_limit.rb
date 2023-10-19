# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Settings
        module Component
          class AccountAndLimit < Page::Base
            view 'app/views/admin/application_settings/_account_and_limit.html.haml' do
              element 'receive-max-input-size-field'
              element 'save-changes-button'
            end

            def set_max_file_size(size)
              fill_element 'receive-max-input-size-field', size
            end

            def save_settings
              click_element 'save-changes-button'
            end
          end
        end
      end
    end
  end
end
