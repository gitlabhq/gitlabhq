# frozen_string_literal: true

module QA
  module Page
    module Project
      module Import
        class RepoByURL < Page::Base
          include Page::Component::Select2

          view 'app/views/projects/_new_project_fields.html.haml' do
            element :select_namespace_dropdown
          end

          def import!(gitlab_repo_path, name)
            fill_git_repository_url_link(gitlab_repo_path)
            fill_project_name(name)
            choose_test_namespace
            click_create_button

            wait_for_success

            go_to_project(name)
          end

          private

          def fill_git_repository_url_link(gitlab_repo_path)
            fill_in 'project_import_url', with: gitlab_repo_path
          end

          def fill_project_name(name)
            fill_in 'project_name', with: name
          end

          def choose_test_namespace
            find('.js-select-namespace').click
            search_and_select(Runtime::Namespace.path)
          end

          def click_create_button
            find('.btn-confirm').click
          end

          def wait_for_success
            wait_until(max_duration: 60, sleep_interval: 5.0, reload: true, skip_finished_loading_check_on_refresh: true) do
              page.has_no_content?('Import in progress', wait: 3.0)
            end
          end

          def go_to_project(name)
            Page::Main::Menu.perform(&:go_to_projects)
            Page::Dashboard::Projects.perform do |dashboard|
              dashboard.go_to_project(name)
            end
          end
        end
      end
    end
  end
end
