# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class Monitor < Page::Base
          include QA::Page::Settings::Common

          view 'app/assets/javascripts/incidents_settings/components/incidents_settings_tabs.vue' do
            element :incidents_settings_content
          end

          view 'app/views/projects/settings/operations/_alert_management.html.haml' do
            element :alerts_settings_content
          end

          def expand_incidents(&block)
            expand_content(:incidents_settings_content) do
              # Fill in with incidents settings
            end
          end

          def expand_alerts(&block)
            expand_content(:alerts_settings_content) do
              Settings::Alerts.perform(&block)
            end
          end
        end
      end
    end
  end
end
