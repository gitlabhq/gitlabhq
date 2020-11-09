# frozen_string_literal: true

module QA
  module Page
    module Project
      module Import
        class Github < Page::Base
          include Page::Component::Select2

          view 'app/views/import/github/new.html.haml' do
            element :personal_access_token_field
            element :authenticate_button
          end

          view 'app/assets/javascripts/import_projects/components/provider_repo_table_row.vue' do
            element :project_import_row
            element :project_namespace_select
            element :project_path_field
            element :import_button
          end

          def add_personal_access_token(personal_access_token)
            fill_element(:personal_access_token_field, personal_access_token)
            click_element(:authenticate_button)
            finished_loading?
          end

          def import!(full_path, name)
            choose_test_namespace(full_path)
            set_path(full_path, name)
            import_project(full_path)
            wait_for_success
          end

          private

          def within_repo_path(full_path)
            wait_until(reload: false) do
              has_element?(:project_import_row, text: full_path)
            end

            project_import_row = find_element(:project_import_row, text: full_path)

            within(project_import_row) do
              yield
            end
          end

          def choose_test_namespace(full_path)
            within_repo_path(full_path) do
              click_element :project_namespace_select
            end

            search_and_select(Runtime::Namespace.path)
          end

          def set_path(full_path, name)
            within_repo_path(full_path) do
              fill_element(:project_path_field, name)
            end
          end

          def import_project(full_path)
            within_repo_path(full_path) do
              click_element(:import_button)
            end
          end

          def wait_for_success
            # TODO: set reload:false and remove skip_finished_loading_check_on_refresh when
            # https://gitlab.com/gitlab-org/gitlab/-/issues/231542 is fixed
            wait_until(max_duration: 60, sleep_interval: 5.0, reload: true, skip_finished_loading_check_on_refresh: true) do
              page.has_content?('Done', wait: 1.0)
            end
          end
        end
      end
    end
  end
end
