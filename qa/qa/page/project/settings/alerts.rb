# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class Alerts < Page::Base
          view 'app/assets/javascripts/alerts_settings/components/alerts_form.vue' do
            element :create_issue_checkbox
            element :incident_templates_dropdown
            element :save_changes_button
            element :incident_templates_item
          end

          def enable_issues_for_incidents
            check_element(:create_issue_checkbox)
          end

          def select_issue_template(template)
            click_element(:incident_templates_dropdown)
            within_element :incident_templates_dropdown do
              find_element(:incident_templates_item, text: template).click
            end
          end

          def save_incident_settings
            click_element :save_changes_button
          end

          def has_template?(template)
            within_element :incident_templates_dropdown do
              has_text?(template)
            end
          end
        end
      end
    end
  end
end
