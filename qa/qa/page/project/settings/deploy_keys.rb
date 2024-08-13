# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class DeployKeys < Page::Base
          view 'app/views/shared/deploy_keys/_index.html.haml' do
            element 'add-new-deploy-key-button'
          end

          view 'app/views/shared/deploy_keys/_form.html.haml' do
            element 'deploy-key-title-field'
            element 'deploy-key-field'
          end

          view 'app/views/shared/deploy_keys/_project_group_form.html.haml' do
            element 'deploy-key-title-field'
            element 'deploy-key-field'
            element 'deploy-key-expires-at-field'
            element 'add-deploy-key-button'
          end

          view 'app/assets/javascripts/deploy_keys/components/app.vue' do
            element 'project-deploy-keys-container'
          end

          view 'app/assets/javascripts/deploy_keys/components/key.vue' do
            element 'key-container'
            element 'key-title-content'
            element 'key-sha256-fingerprint-content'
          end

          def add_new_key
            click_element('add-new-deploy-key-button')
          end

          def add_key
            click_element('add-deploy-key-button')
          end

          def fill_key_title(title)
            fill_element('deploy-key-title-field', title)
          end

          def fill_key_value(key)
            fill_element('deploy-key-field', key)
          end

          def find_sha256_fingerprint(title)
            within_project_deploy_keys do
              find_element('key-container', text: title)
                .find(element_selector_css('key-sha256-fingerprint-content')).text
            end
          end

          def has_key?(title, sha256_fingerprint)
            within_project_deploy_keys do
              find_element('key-container', text: title)
                .has_css?(element_selector_css('key-sha256-fingerprint-content'), text: sha256_fingerprint)
            end
          end

          def key_title
            within_project_deploy_keys do
              find_element('key-title-content').text
            end
          end

          private

          def within_project_deploy_keys
            has_element?('project-deploy-keys-container', wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)

            within_element('project-deploy-keys-container') do
              yield
            end
          end
        end
      end
    end
  end
end
