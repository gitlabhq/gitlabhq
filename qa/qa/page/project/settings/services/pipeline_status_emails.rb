# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        module Services
          class PipelineStatusEmails < QA::Page::Base
            view 'app/assets/javascripts/integrations/edit/components/integration_form.vue' do
              element 'recipients-div', %q(:data-testid="`${field.name}-div`") # rubocop:disable QA/ElementWithPattern -- needed for qa:selectors job to pass
              element 'notify_only_broken_pipelines-div', %q(:data-testid="`${field.name}-div`") # rubocop:disable QA/ElementWithPattern -- needed for qa:selectors job to pass
            end

            view 'app/assets/javascripts/integrations/edit/components/integration_form_actions.vue' do
              element 'save-changes-button'
            end

            def set_recipients(emails)
              within_element 'recipients-div' do
                fill_in 'Recipients', with: emails.join(',')
              end
            end

            def toggle_notify_broken_pipelines
              within_element 'notify_only_broken_pipelines-div' do
                uncheck 'Notify only broken pipelines', allow_label_click: true
              end
            end

            def click_save_button
              click_element('save-changes-button')
            end
          end
        end
      end
    end
  end
end
