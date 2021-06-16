# frozen_string_literal: true

module QA
  module Page
    module Project
      module Monitor
        module Incidents
          class Index < Page::Base
            view 'app/assets/javascripts/incidents/components/incidents_list.vue' do
              element :create_incident_button
            end

            def create_incident
              click_element :create_incident_button
            end
          end
        end
      end
    end
  end
end
