# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class DeployTokens < Page::Base
          view 'app/views/shared/deploy_tokens/_form.html.haml' do
            element :deploy_token_name
            element :deploy_token_expires_at
            element :deploy_token_read_repository
            element :deploy_token_read_registry
            element :create_deploy_token
          end

          view 'app/views/shared/deploy_tokens/_new_deploy_token.html.haml' do
            element :created_deploy_token_section
            element :deploy_token_user
            element :deploy_token
          end

          def fill_token_name(name)
            fill_element :deploy_token_name, name
          end

          def fill_token_expires_at(expires_at)
            fill_element :deploy_token_expires_at, expires_at.to_s + "\n"
          end

          def fill_scopes(read_repository:, read_registry:)
            check_element :deploy_token_read_repository if read_repository
            check_element :deploy_token_read_registry if read_registry
          end

          def add_token
            click_element :create_deploy_token
          end

          def token_username
            within_new_project_deploy_token do
              find_element(:deploy_token_user).value
            end
          end

          def token_password
            within_new_project_deploy_token do
              find_element(:deploy_token).value
            end
          end

          private

          def within_new_project_deploy_token
            has_element?(:created_deploy_token_section, wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)

            within_element(:created_deploy_token_section) do
              yield
            end
          end
        end
      end
    end
  end
end
