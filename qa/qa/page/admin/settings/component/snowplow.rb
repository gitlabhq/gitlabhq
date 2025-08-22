# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Settings
        module Component
          class Snowplow < Page::Base
            include QA::Page::Settings::Common

            view 'app/views/admin/application_settings/metrics_and_profiling.html.haml' do
              element 'product-usage-data-settings-content'
            end

            view 'app/views/admin/application_settings/_product_usage_data.html.haml' do
              element 'snowplow-enabled-checkbox'
            end

            def enable_snowplow_tracking
              expand_content('product-usage-data-settings-content') do
                check_snowplow_enabled_checkbox
                click_button('Save changes')
              end
            end

            def disable_snowplow_tracking
              expand_content('product-usage-data-settings-content') do
                uncheck_snowplow_enabled_checkbox
                click_button('Save changes')
              end
            end

            private

            def check_snowplow_enabled_checkbox
              check_element('snowplow-enabled-checkbox', true)
            end

            def uncheck_snowplow_enabled_checkbox
              uncheck_element('snowplow-enabled-checkbox', true)
            end
          end
        end
      end
    end
  end
end
