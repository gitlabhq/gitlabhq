# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Settings
        module Component
          class Snowplow < Page::Base
            include QA::Page::Settings::Common

            view 'app/views/admin/application_settings/_snowplow.html.haml' do
              element 'snowplow-settings-content'
              element 'snowplow-enabled-checkbox'
              element 'save-changes-button'
            end

            def enable_snowplow_tracking
              expand_content('snowplow-settings-content') do
                check_snowplow_enabled_checkbox
                click_save_changes_button
              end
            end

            def disable_snowplow_tracking
              expand_content('snowplow-settings-content') do
                uncheck_snowplow_enabled_checkbox
                click_save_changes_button
              end
            end

            private

            def check_snowplow_enabled_checkbox
              check_element('snowplow-enabled-checkbox', true)
            end

            def uncheck_snowplow_enabled_checkbox
              uncheck_element('snowplow-enabled-checkbox', true)
            end

            def click_save_changes_button
              click_element 'save-changes-button'
            end
          end
        end
      end
    end
  end
end
