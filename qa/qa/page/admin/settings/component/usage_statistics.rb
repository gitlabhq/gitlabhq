# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Settings
        module Component
          class UsageStatistics < Page::Base
            view 'app/views/admin/application_settings/_usage.html.haml' do
              element 'enable-usage-data-checkbox'
            end

            def has_usage_data_checkbox_checked_and_disabled?
              checkbox = find_element('enable-usage-data-checkbox', visible: false)
              checkbox.disabled? && checkbox.checked?
            end
          end
        end
      end
    end
  end
end
