# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        module Services
          class Jenkins < QA::Page::Base
            view 'app/assets/javascripts/integrations/edit/components/dynamic_field.vue' do
              element 'service-jenkins_url-field', ':data-testid="`${fieldId}-field`"' # rubocop:disable QA/ElementWithPattern -- needed for qa:selectors job to pass
              element 'service-project_name-field', ':data-testid="`${fieldId}-field`"' # rubocop:disable QA/ElementWithPattern -- needed for qa:selectors job to pass
              element 'service-username-field', ':data-testid="`${fieldId}-field`"' # rubocop:disable QA/ElementWithPattern -- needed for qa:selectors job to pass
              element 'service-password-field', ':data-testid="`${fieldId}-field`"' # rubocop:disable QA/ElementWithPattern -- needed for qa:selectors job to pass
            end

            view 'app/assets/javascripts/integrations/edit/components/integration_form_actions.vue' do
              element 'save-changes-button'
            end

            def setup_service_with(jenkins_url:, project_name:, username:, password:)
              set_jenkins_url(jenkins_url)
              set_project_name(project_name)
              set_username(username)
              set_password(password)
              click_save_changes_button
            end

            private

            def set_jenkins_url(jenkins_url)
              fill_element('service-jenkins_url-field', jenkins_url)
            end

            def set_project_name(project_name)
              fill_element('service-project_name-field', project_name)
            end

            def set_username(username)
              fill_element('service-username-field', username)
            end

            def set_password(password)
              fill_element('service-password-field', password)
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
