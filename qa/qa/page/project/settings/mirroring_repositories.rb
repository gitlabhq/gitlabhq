# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class MirroringRepositories < Page::Base
          view 'app/views/projects/mirrors/_authentication_method.html.haml' do
            element :authentication_method
            element :password
          end

          view 'app/views/projects/mirrors/_mirror_repos.html.haml' do
            element :mirror_repository_url_input
            element :mirror_repository_button
            element :mirror_repository_url_cell
            element :mirror_last_update_at_cell
            element :mirror_error_badge
            element :mirrored_repository_row
            element :copy_public_key_button
          end

          view 'app/views/projects/mirrors/_mirror_repos_form.html.haml' do
            element :mirror_direction
          end

          view 'app/views/shared/_remote_mirror_update_button.html.haml' do
            element :update_now_button
            element :updating_button
          end

          view 'app/views/projects/mirrors/_ssh_host_keys.html.haml' do
            element :detect_host_keys
            element :fingerprints_list
          end

          view 'app/views/projects/mirrors/_authentication_method.html.haml' do
            element :authentication_method
            element :password
          end

          def repository_url=(value)
            fill_element :mirror_repository_url_input, value
          end

          def password=(value)
            fill_element :password, value
          end

          def mirror_direction=(value)
            raise ArgumentError, "Mirror direction must be 'Push' or 'Pull'" unless %w(Push Pull).include? value

            select_element(:mirror_direction, value)

            # Changing the mirror direction causes the fields below to change,
            # and that change is animated, so we need to wait for the animation
            # to complete otherwise changes to those fields could fail
            wait_for_animated_element :authentication_method
          end

          def authentication_method=(value)
            raise ArgumentError, "Authentication method must be 'SSH public key', 'Password', or 'None'" unless %w(Password None SSH\ public\ key).include? value

            select_element(:authentication_method, value)
          end

          def public_key(url)
            row_index = find_repository_row_index url

            within_element_by_index(:mirrored_repository_row, row_index) do
              find_element(:copy_public_key_button)['data-clipboard-text']
            end
          end

          def detect_host_keys
            click_element :detect_host_keys

            # The host key detection process is interrupted if we navigate away
            # from the page before the fingerprint appears.
            wait(max: 5) do
              find_element(:fingerprints_list).has_text? /.*/
            end
          end

          def mirror_repository
            click_element :mirror_repository_button
          end

          def update(url)
            row_index = find_repository_row_index url

            within_element_by_index(:mirrored_repository_row, row_index) do
              # When a repository is first mirrored, the update process might
              # already be started, so the button is already "clicked"
              click_element :update_now_button unless has_element? :updating_button
            end

            # Wait a few seconds for the sync to occur and then refresh the page
            # so that 'last update' shows 'just now' or a period in seconds
            sleep 5
            refresh

            wait(interval: 1) do
              within_element_by_index(:mirrored_repository_row, row_index) do
                last_update = find_element(:mirror_last_update_at_cell, wait: 0)
                last_update.has_text?('just now') || last_update.has_text?('seconds')
              end
            end

            # Fail early if the page still shows that there has been no update
            within_element_by_index(:mirrored_repository_row, row_index) do
              find_element(:mirror_last_update_at_cell, wait: 0).assert_no_text('Never')
              assert_no_element(:mirror_error_badge)
            end
          end

          private

          def find_repository_row_index(target_url)
            wait(max: 5, reload: false) do
              all_elements(:mirror_repository_url_cell, minimum: 1).index do |url|
                # The url might be a sanitized url but the target_url won't be so
                # we compare just the paths instead of the full url
                URI.parse(url.text).path == target_url.path
              end
            end
          end
        end
      end
    end
  end
end

QA::Page::Project::Settings::MirroringRepositories.prepend_if_ee('QA::EE::Page::Project::Settings::MirroringRepositories')
