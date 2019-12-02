# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class DeployKeys < Page::Base
          view 'app/views/projects/deploy_keys/_form.html.haml' do
            element :deploy_key_title, 'text_field :title' # rubocop:disable QA/ElementWithPattern
            element :deploy_key_key, 'text_area :key' # rubocop:disable QA/ElementWithPattern
          end

          view 'app/assets/javascripts/deploy_keys/components/app.vue' do
            element :deploy_keys_section, /class=".*deploy\-keys.*"/ # rubocop:disable QA/ElementWithPattern
            element :project_deploy_keys
          end

          view 'app/assets/javascripts/deploy_keys/components/key.vue' do
            element :key
            element :key_title
            element :key_fingerprint
          end

          def add_key
            click_on 'Add key'
          end

          def fill_key_title(title)
            fill_in 'deploy_key_title', with: title
          end

          def fill_key_value(key)
            fill_in 'deploy_key_key', with: key
          end

          def find_fingerprint(title)
            within_project_deploy_keys do
              find_element(:key, text: title)
                .find(element_selector_css(:key_fingerprint)).text
            end
          end

          def has_key?(title, fingerprint)
            within_project_deploy_keys do
              find_element(:key, text: title)
                .has_css?(element_selector_css(:key_fingerprint), text: fingerprint)
            end
          end

          def key_title
            within_project_deploy_keys do
              find_element(:key_title).text
            end
          end

          def key_fingerprint
            within_project_deploy_keys do
              find_element(:key_fingerprint).text
            end
          end

          private

          def within_project_deploy_keys
            wait(reload: false) do
              has_element?(:project_deploy_keys)
            end

            within_element(:project_deploy_keys) do
              yield
            end
          end
        end
      end
    end
  end
end
