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
            element :mirror_repository_url
            element :mirror_last_update_at
            element :mirrored_repository_row
          end

          view 'app/views/projects/mirrors/_mirror_repos_form.html.haml' do
            element :mirror_direction
          end

          view 'app/views/shared/_remote_mirror_update_button.html.haml' do
            element :update_now_button
          end

          def repository_url=(value)
            fill_element :mirror_repository_url_input, value
          end

          def password=(value)
            fill_element :password, value
          end

          def mirror_direction=(value)
            raise ArgumentError, "Mirror direction must be :push or :pull" unless [:push, :pull].include? value

            select_element(:mirror_direction, value)
          end

          def authentication_method=(value)
            raise ArgumentError, "Authentication method must be :password or :none" unless [:password, :none].include? value

            select_element(:authentication_method, value)
          end

          def mirror_repository
            click_element :mirror_repository_button
          end

          def update(url)
            row_index = find_repository_row_index url

            within_element_by_index(:mirrored_repository_row, row_index) do
              click_element :update_now_button
            end

            # Wait a few seconds for the sync to occur and then refresh the page
            # so that 'last update' shows 'just now' or a period in seconds
            sleep 5
            refresh

            wait(interval: 1) do
              within_element_by_index(:mirrored_repository_row, row_index) do
                last_update = find_element(:mirror_last_update_at, wait: 0)
                last_update.has_text?('just now') || last_update.has_text?('seconds')
              end
            end

            # Fail early if the page still shows that there has been no update
            within_element_by_index(:mirrored_repository_row, row_index) do
              find_element(:mirror_last_update_at, wait: 0).assert_no_text('Never')
            end
          end

          private

          def find_repository_row_index(target_url)
            all_elements(:mirror_repository_url).index do |url|
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

QA::Page::Project::Settings::MirroringRepositories.prepend_if_ee('QA::EE::Page::Project::Settings::MirroringRepositories')
