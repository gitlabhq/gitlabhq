# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Settings
        module Component
          class PerformanceBar < Page::Base
            view 'app/views/admin/application_settings/_performance_bar.html.haml' do
              element :enable_performance_bar_checkbox
              element :save_changes_button
            end

            def enable_performance_bar
              check_element(:enable_performance_bar_checkbox)
              Capybara.current_session.driver.browser.manage.add_cookie(name: 'perf_bar_enabled', value: 'true')
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
