# frozen_string_literal: true

module QA
  module Page
    module Dashboard
      class Projects < Page::Base
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
          filter_input = find_element('filtered-search-term-input')
          filter_input.click
          filter_input.set(name)
          click_element 'search-button'
          wait_for_requests
        end

        def go_to_project(name)
          filter_by_name(name)

          find_link(text: name).click
        end

        def click_new_project_button
          click_element('new-project-button', Page::Project::New)
        end

        # The tab names of the HAML and Vue version of the UI differ slightly.
        # The Vue version defaults to a "Contributed" tab where-as the HAML version
        # defaults to a "Yours" tab. Here we conditionally click the "Member" tab
        # if it exists (only on the Vue version). This allows the tests to
        # pass in both versions.
        # We can remove this conditional check when code behind the
        # your_work_projects_vue feature flag becomes the default.
        def click_member_tab
          text = 'Member'
          click_link(text) if has_link?(text)
          wait_for_requests
        end

        def self.path
          '/'
        end

        def clear_project_filter
          click_element 'filtered-search-clear-button'
          wait_for_requests
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
