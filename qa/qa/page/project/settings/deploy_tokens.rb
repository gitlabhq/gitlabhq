# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class DeployTokens < Page::Base
          view 'app/views/shared/deploy_tokens/_form.html.haml' do
            element :deploy_token_name_field
            element :deploy_token_expires_at_field
            element :deploy_token_read_repository_checkbox
            element :deploy_token_read_package_registry_checkbox
            element :deploy_token_read_registry_checkbox
            element :create_deploy_token_button
          end

          view 'app/views/shared/deploy_tokens/_new_deploy_token.html.haml' do
            element :created_deploy_token_container
            element :deploy_token_user_field
            element :deploy_token_field
          end

          def fill_token_name(name)
            fill_element(:deploy_token_name_field, name)
          end

          def fill_token_expires_at(expires_at)
            fill_element(:deploy_token_expires_at_field, expires_at.to_s + "\n")
          end

          def fill_scopes(read_repository: false, read_registry: false, read_package_registry: false)
            check_element(:deploy_token_read_repository_checkbox) if read_repository
            check_element(:deploy_token_read_package_registry_checkbox) if read_package_registry
            check_element(:deploy_token_read_registry_checkbox) if read_registry
          end

          def add_token
            click_element(:create_deploy_token_button)
          end

          def token_username
            within_new_project_deploy_token do
              find_element(:deploy_token_user_field).value
            end
          end

          def token_password
            within_new_project_deploy_token do
              find_element(:deploy_token_field).value
            end
          end

          private

          def within_new_project_deploy_token
            has_element?(:created_deploy_token_container, wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)

            within_element(:created_deploy_token_container) do
              yield
            end
          end
        end
      end
    end
  end
end
