module QA
  module Page
    module Project
      module Settings
        class DeployKeys < Page::Base
          view 'app/views/projects/deploy_keys/_form.html.haml' do
            element :deploy_key_title, 'text_field :title'
            element :deploy_key_key, 'text_area :key'
          end

          view 'app/assets/javascripts/deploy_keys/components/app.vue' do
            element :deploy_keys_section, /class=".*deploy\-keys.*"/
            element :project_deploy_keys, 'class="qa-project-deploy-keys"'
          end

          view 'app/assets/javascripts/deploy_keys/components/key.vue' do
            element :key_title, /class=".*qa-key-title.*"/
            element :key_fingerprint, /class=".*qa-key-fingerprint.*"/
          end

          def fill_key_title(title)
            fill_in 'deploy_key_title', with: title
          end

          def fill_key_value(key)
            fill_in 'deploy_key_key', with: key
          end

          def add_key
            click_on 'Add key'
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

          def key_titles
            within_project_deploy_keys do
              all_elements(:key_title)
            end
          end

          def key_fingerprints
            within_project_deploy_keys do
              all_elements(:key_fingerprint)
            end
          end

          private

          def within_project_deploy_keys
            within_element(:project_deploy_keys) do
              yield
            end
          end
        end
      end
    end
  end
end
