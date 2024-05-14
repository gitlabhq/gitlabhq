# frozen_string_literal: true

module QA
  module Page
    module Dashboard
      class Projects < Page::Base
        view 'app/views/shared/projects/_search_form.html.haml' do
          element 'project-filter-form-container', required: true
        end

        view 'app/views/shared/projects/_project.html.haml' do
          element 'project-content'
          element 'user-access-role'
        end

        view 'app/views/dashboard/_projects_head.html.haml' do
          element 'new-project-button'
        end

        view 'app/views/dashboard/projects/_blank_state_welcome.html.haml' do
          element 'new-project-button'
        end

        view 'app/views/dashboard/projects/_blank_state_admin_welcome.html.haml' do
          element 'new-project-button'
        end

        def has_filtered_project_with_access_role?(project_name, access_role)
          # Retry as in some situations the filter may fail if sidekiq hasn't had a chance
          # to process all jobs after the project create
          QA::Support::Retrier.retry_until(max_duration: 60, retry_on_exception: true) do
            filter_by_name(project_name)
            has_project_with_access_role?(project_name, access_role)
          end
        end

        def filter_by_name(name)
          within_element('project-filter-form-container') do
            fill_in :name, with: name
          end
        end

        def go_to_project(name)
          filter_by_name(name)

          find_link(text: name).click
        end

        def click_new_project_button
          click_element('new-project-button', Page::Project::New)
        end

        def self.path
          '/'
        end

        def clear_project_filter
          fill_element('project-filter-form-container', "")
        end

        private

        def has_project_with_access_role?(project_name, access_role)
          within_element('project-content', text: project_name) do
            has_element?('user-access-role', text: access_role)
          end
        end
      end
    end
  end
end

QA::Page::Dashboard::Projects.prepend_mod_with('Page::Dashboard::Projects', namespace: QA)
