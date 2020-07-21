# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class Operations < Page::Base
          include QA::Page::Settings::Common

          view 'app/assets/javascripts/incidents_settings/components/incidents_settings_tabs.vue' do
            element :incidents_settings_content
          end

          def expand_incidents(&block)
            expand_content(:incidents_settings_content) do
              Settings::Incidents.perform(&block)
            end
          end
        end
      end
    end
  end
end
