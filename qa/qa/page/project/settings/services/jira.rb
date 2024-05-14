# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        module Services
          class Jira < QA::Page::Base
            view 'app/assets/javascripts/integrations/edit/components/dynamic_field.vue' do
              element 'service-url-field', ':data-testid="`${fieldId}-field`"' # rubocop:disable QA/ElementWithPattern -- needed for qa:selectors job to pass
              element 'service-username-field', ':data-testid="`${fieldId}-field`"' # rubocop:disable QA/ElementWithPattern -- needed for qa:selectors job to pass
              element 'service-password-field', ':data-testid="`${fieldId}-field`"' # rubocop:disable QA/ElementWithPattern -- needed for qa:selectors job to pass
            end

            view 'app/assets/javascripts/integrations/edit/components/jira_trigger_fields.vue' do
              element 'jira-issue-transition-enabled-checkbox'
              element 'jira-issue-transition-automatic-true-radio', ':data-testid="`jira-issue-transition-automatic-${issueTransitionOption.value}-radio`"' # rubocop:disable QA/ElementWithPattern -- needed for qa:selectors job to pass
              element 'jira-issue-transition-automatic-false-radio', ':data-testid="`jira-issue-transition-automatic-${issueTransitionOption.value}-radio`"' # rubocop:disable QA/ElementWithPattern -- needed for qa:selectors job to pass
              element 'jira-issue-transition-id-field'
            end

            view 'app/assets/javascripts/integrations/edit/components/integration_form_actions.vue' do
              element 'save-changes-button'
            end

            view 'app/assets/javascripts/integrations/edit/components/jira_issues_fields.vue' do
              element 'jira-issues-enabled-checkbox'
              element 'jira-project-keys-field'
            end

            def setup_service_with(url:)
              QA::Runtime::Logger.info "Setting up JIRA"

              set_jira_server_url(url)
              set_username(Runtime::Env.jira_admin_username)
              set_password(Runtime::Env.jira_admin_password)

              enable_transitions
              use_custom_transitions
              set_transition_ids('11,21,31,41')

              yield self if block_given?

              click_save_changes_and_wait
            end

            def enable_jira_issues
              check_element('jira-issues-enabled-checkbox', true)
            end

            def set_jira_project_keys(key)
              fill_element('jira-project-keys-field', key)
            end

            def click_save_changes_and_wait
              click_save_changes_button
              wait_until(reload: false) do
                has_element?('save-changes-button', wait: 1) ? !find_element('save-changes-button').disabled? : true
              end
            end

            private

            def set_jira_server_url(url)
              fill_element('service-url-field', url)
            end

            def set_username(username)
              fill_element('service-username-field', username)
            end

            def set_password(password)
              fill_element('service-password-field', password)
            end

            def enable_transitions
              check_element('jira-issue-transition-enabled-checkbox', true)
            end

            def use_automatic_transitions
              choose_element('jira-issue-transition-automatic-true-radio', true)
            end

            def use_custom_transitions
              choose_element('jira-issue-transition-automatic-false-radio', true)
            end

            def set_transition_ids(transition_ids)
              fill_element('jira-issue-transition-id-field', transition_ids)
            end

            def click_save_changes_button
              click_element('save-changes-button')
            end
          end
        end
      end
    end
  end
end

QA::Page::Project::Settings::Services::Jira.prepend_mod_with('Page::Project::Settings::Services::Jira', namespace: QA)
