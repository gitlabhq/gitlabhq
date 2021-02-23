# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        module Services
          class Jira < QA::Page::Base
            view 'app/assets/javascripts/integrations/edit/components/dynamic_field.vue' do
              element :service_url_field, ':data-qa-selector="`${fieldId}_field`"' # rubocop:disable QA/ElementWithPattern
              element :service_username_field, ':data-qa-selector="`${fieldId}_field`"' # rubocop:disable QA/ElementWithPattern
              element :service_password_field, ':data-qa-selector="`${fieldId}_field`"' # rubocop:disable QA/ElementWithPattern
              element :service_jira_issue_transition_id_field, ':data-qa-selector="`${fieldId}_field`"' # rubocop:disable QA/ElementWithPattern
            end

            view 'app/assets/javascripts/integrations/edit/components/integration_form.vue' do
              element :save_changes_button
            end

            def setup_service_with(url:)
              QA::Runtime::Logger.info "Setting up JIRA"

              set_jira_server_url(url)
              set_username(Runtime::Env.jira_admin_username)
              set_password(Runtime::Env.jira_admin_password)
              set_transaction_ids('11,21,31,41')

              click_save_changes_button
              wait_until(reload: false) do
                has_element?(:save_changes_button, wait: 1) ? !find_element(:save_changes_button).disabled? : true
              end
            end

            private

            def set_jira_server_url(url)
              fill_element(:service_url_field, url)
            end

            def set_username(username)
              fill_element(:service_username_field, username)
            end

            def set_password(password)
              fill_element(:service_password_field, password)
            end

            def set_transaction_ids(transaction_ids)
              fill_element(:service_jira_issue_transition_id_field, transaction_ids)
            end

            def click_save_changes_button
              click_element :save_changes_button
            end
          end
        end
      end
    end
  end
end
