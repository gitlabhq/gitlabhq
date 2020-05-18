# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class Operations < Page::Base
          include QA::Page::Settings::Common

          view 'app/views/projects/settings/operations/_incidents.html.haml' do
            element :incidents_settings_content
          end

          def expand_incidents(&block)
            expand_section(:incidents_settings_content) do
              Settings::Incidents.perform(&block)
            end
          end
        end
      end
    end
  end
end
