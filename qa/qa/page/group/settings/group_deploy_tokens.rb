# frozen_string_literal: true

module QA
  module Page
    module Group
      module Settings
        class GroupDeployTokens < Page::Base
          view 'app/views/shared/deploy_tokens/_form.html.haml' do
            element 'deploy-token-name-field'
            element 'deploy-token-expires-at-field'
            element 'deploy-token-read-repository-checkbox'
            element 'deploy-token-read-package-registry-checkbox'
            element 'deploy-token-read-registry-checkbox'
            element 'deploy-token-write-package-registry-checkbox'
            element 'create-deploy-token-button'
          end

          view 'app/views/shared/deploy_tokens/_new_deploy_token.html.haml' do
            element 'created-deploy-token-container'
            element 'deploy-token-user-field'
            element 'deploy-token-field'
          end

          def fill_token_name(name)
            fill_element('deploy-token-name-field', name)
          end

          def fill_token_expires_at(expires_at)
            fill_element('deploy-token-expires-at-field', expires_at.to_s + "\n")
          end

          def fill_scopes(read_repository: false, read_registry: false, read_package_registry: false, write_package_registry: false )
            check_element('deploy-token-read-repository-checkbox', true) if read_repository
            check_element('deploy-token-read-package-registry-checkbox', true) if read_package_registry
            check_element('deploytoken-read-registry-checkbox', true) if read_registry
            check_element('deploy-token-write-package-registry-checkbox', true) if write_package_registry
          end

          def add_token
            click_element('create-deploy-token-button')
          end

          def token_username
            within_new_project_deploy_token do
              find_element('deploy-token-user-field').value
            end
          end

          def token_password
            within_new_project_deploy_token do
              find_element('deploy-token-field').value
            end
          end

          private

          def within_new_project_deploy_token(&block)
            has_element?('created-deploy-token-container', wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)

            within_element('created-deploy-token-container', &block)
          end
        end
      end
    end
  end
end
