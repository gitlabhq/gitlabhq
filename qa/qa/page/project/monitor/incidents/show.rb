# frozen_string_literal: true

module QA
  module Page
    module Project
      module Monitor
        module Incidents
          class Show < Page::Base
            include Page::Component::Note
            include Page::Component::Issuable::Sidebar

            view 'app/assets/javascripts/sidebar/components/severity/sidebar_severity_widget.vue' do
              element 'incident-severity'
              element 'severity-block-container'
            end

            def has_severity?(severity)
              wait_severity_block_finish_loading do
                has_element?('incident-severity', text: severity)
              end
            end

            private

            def wait_severity_block_finish_loading
              within_element('severity-block-container') do
                wait_until(reload: false, max_duration: 10, sleep_interval: 1) do
                  finished_loading_block?
                  yield
                end
              end
            end
          end
        end
      end
    end
  end
end

QA::Page::Project::Monitor::Incidents::Show.prepend_mod_with('Page::Project::Monitor::Incidents::Show', namespace: QA)
