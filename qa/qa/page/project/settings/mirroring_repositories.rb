# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class MirroringRepositories < Page::Base
          view 'app/views/projects/mirrors/_authentication_method.html.haml' do
            element 'authentication-method-field'
            element 'username-field'
            element 'password-field'
          end

          view 'app/views/projects/mirrors/_mirror_repos.html.haml' do
            element 'mirror-repository-url-field'
            element 'mirror-repository-button'
            element 'add-new-mirror'
          end

          view 'app/views/projects/mirrors/_mirror_repos_list.html.haml' do
            element 'mirror-repository-url-content'
            element 'mirror-last-update-at-content'
            element 'mirror-error-badge-content'
            element 'mirrored-repository-row-container'
            element 'copy-public-key-button'
          end

          view 'app/views/projects/mirrors/_mirror_repos_form.html.haml' do
            element 'mirror-direction-field'
          end

          view 'app/views/shared/_remote_mirror_update_button.html.haml' do
            element 'update-now-button'
          end

          view 'app/views/projects/mirrors/_ssh_host_keys.html.haml' do
            element 'detect-host-keys'
            element 'fingerprints-list'
          end

          def repository_url=(value)
            click_element 'add-new-mirror'
            fill_element 'mirror-repository-url-field', value
          end

          def username=(value)
            fill_element 'username-field', value
          end

          def password=(value)
            fill_element 'password-field', value
          end

          def mirror_direction=(value)
            raise ArgumentError, "Mirror direction must be 'Push' or 'Pull'" unless %w[Push Pull].include?(value)

            select_element('mirror-direction-field', value)

            # Changing the mirror direction causes the fields below to change,
            # and that change is animated, so we need to wait for the animation
            # to complete otherwise changes to those fields could fail
            wait_for_animated_element 'authentication-method-field'
          end

          def authentication_method=(value)
            unless ['Password', 'None', 'SSH public key'].include?(value)
              raise ArgumentError, "Authentication method must be 'SSH public key', 'Password', or 'None'"
            end

            select_element('authentication-method-field', value)
          end

          def public_key(url)
            row_index = find_repository_row_index url

            within_element_by_index('mirrored-repository-row-container', row_index) do
              find_element('copy-public-key-button')['data-clipboard-text']
            end
          end

          def detect_host_keys
            click_element 'detect-host-keys'

            # The host key detection process is interrupted if we navigate away
            # from the page before the fingerprint appears.
            find_element('fingerprints-list', text: /.*/, wait: 60)
          end

          def mirror_repository
            click_element 'mirror-repository-button'
          end

          def update_uri(uri)
            row_index = find_repository_row_index(uri)
            within_element_by_index('mirrored-repository-row-container', row_index) do
              # When a repository is first mirrored, the update process might
              # already be started, so the button is already "clicked"
              click_element 'update-now-button' if has_element?('update-now-button', wait: 0)
            end
          end

          def verify_update(url)
            refresh

            row_index = find_repository_row_index(url)

            wait_until(sleep_interval: 1) do
              within_element_by_index('mirrored-repository-row-container', row_index) do
                last_update = find_element('mirror-last-update-at-content', wait: 0)
                last_update.has_text?('just now') || last_update.has_text?('seconds')
              end
            end

            # Fail early if the page still shows that there has been no update
            within_element_by_index('mirrored-repository-row-container', row_index) do
              find_element('mirror-last-update-at-content', wait: 0).assert_no_text('Never')
              assert_no_element('mirror-error-badge-content')
            end
          end

          private

          def find_repository_row_index(target_url)
            wait_until(max_duration: 5, reload: false) do
              all_elements('mirror-repository-url-content', minimum: 1).index do |url|
                # The url might be a sanitized url but the target_url won't be so
                # we compare just the paths instead of the full url
                # We also must remove any badges from the url (e.g. All Branches)
                URI.parse(url.text.split("\n").first).path == target_url.path
              end
            end
          end
        end
      end
    end
  end
end

QA::Page::Project::Settings::MirroringRepositories.prepend_mod_with( # rubocop:disable Cop/InjectEnterpriseEditionModule
  'Page::Project::Settings::MirroringRepositories',
  namespace: QA
)
