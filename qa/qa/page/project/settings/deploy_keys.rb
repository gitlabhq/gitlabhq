# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class DeployKeys < Page::Base
          view 'app/views/shared/deploy_keys/_form.html.haml' do
            element :deploy_key_title_field
            element :deploy_key_field
          end

          view 'app/views/shared/deploy_keys/_project_group_form.html.haml' do
            element :deploy_key_title_field
            element :deploy_key_field
            element :add_deploy_key_button
          end

          view 'app/assets/javascripts/deploy_keys/components/app.vue' do
            element :project_deploy_keys_container
          end

          view 'app/assets/javascripts/deploy_keys/components/key.vue' do
            element :key_container
            element :key_title_content
            element :key_md5_fingerprint_content
          end

          def add_key
            click_element(:add_deploy_key_button)
          end

          def fill_key_title(title)
            fill_element(:deploy_key_title_field, title)
          end

          def fill_key_value(key)
            fill_element(:deploy_key_field, key)
          end

          def find_md5_fingerprint(title)
            within_project_deploy_keys do
              find_element(:key_container, text: title)
                .find(element_selector_css(:key_md5_fingerprint_content)).text.delete_prefix('MD5:')
            end
          end

          def has_key?(title, md5_fingerprint)
            within_project_deploy_keys do
              find_element(:key_container, text: title)
                .has_css?(element_selector_css(:key_md5_fingerprint_content), text: "MD5:#{md5_fingerprint}")
            end
          end

          def key_title
            within_project_deploy_keys do
              find_element(:key_title_content).text
            end
          end

          private

          def within_project_deploy_keys
            has_element?(:project_deploy_keys_container, wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)

            within_element(:project_deploy_keys_container) do
              yield
            end
          end
        end
      end
    end
  end
end
