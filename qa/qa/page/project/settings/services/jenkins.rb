# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        module Services
          class Jenkins < QA::Page::Base
            view 'app/assets/javascripts/integrations/edit/components/dynamic_field.vue' do
              element :jenkins_url_field, ':data-qa-selector="`${fieldId}_field`"' # rubocop:disable QA/ElementWithPattern
              element :project_name_field, ':data-qa-selector="`${fieldId}_field`"' # rubocop:disable QA/ElementWithPattern
              element :username_field, ':data-qa-selector="`${fieldId}_field`"' # rubocop:disable QA/ElementWithPattern
              element :password_field, ':data-qa-selector="`${fieldId}_field`"' # rubocop:disable QA/ElementWithPattern
            end

            view 'app/assets/javascripts/integrations/edit/components/integration_form.vue' do
              element :save_changes_button
            end

            def setup_service_with(jenkins_url:, project_name:)
              set_jenkins_url(jenkins_url)
              set_project_name(project_name)
              set_username('admin')
              set_password('password')
              click_save_changes_button
            end

            private

            def set_jenkins_url(jenkins_url)
              fill_element(:jenkins_url_field, jenkins_url)
            end

            def set_project_name(project_name)
              fill_element(:project_name_field, project_name)
            end

            def set_username(username)
              fill_element(:username_field, username)
            end

            def set_password(password)
              fill_element(:password_field, password)
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
