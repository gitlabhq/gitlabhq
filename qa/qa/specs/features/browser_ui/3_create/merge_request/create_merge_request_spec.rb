# frozen_string_literal: true

module QA
  # Failure issue: https://gitlab.com/gitlab-org/quality/staging/issues/50
  context 'Create', :quarantine do
    describe 'Merge request creation' do
      it 'user creates a new merge request', :smoke do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.act { sign_in_using_credentials }

        current_project = Resource::Project.fabricate! do |project|
          project.name = 'project-with-merge-request'
        end

        merge_request_title = 'This is a merge request'
        merge_request_description = 'Great feature'

        Resource::MergeRequest.fabricate! do |merge_request|
          merge_request.title = merge_request_title
          merge_request.description = merge_request_description
          merge_request.project = current_project
        end

        expect(page).to have_content(merge_request_title)
        expect(page).to have_content(merge_request_description)
        expect(page).to have_content('Opened just now')
      end

      it 'user creates a new merge request with a milestone and label' do
        gitlab_account_username = "@#{Runtime::User.username}"

        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.act { sign_in_using_credentials }

        current_project = Resource::Project.fabricate! do |project|
          project.name = 'project-with-merge-request-and-milestone'
        end

        current_milestone = Resource::ProjectMilestone.fabricate! do |milestone|
          milestone.title = 'unique-milestone'
          milestone.project = current_project
        end

        new_label = Resource::Label.fabricate_via_browser_ui! do |label|
          label.project = current_project
          label.title = 'qa-mr-test-label'
          label.description = 'Merge Request label'
        end

        merge_request_title = 'This is a merge request with a milestone and a label'
        merge_request_description = 'Great feature with milestone'

        Resource::MergeRequest.fabricate! do |merge_request|
          merge_request.title = merge_request_title
          merge_request.description = merge_request_description
          merge_request.project = current_project
          merge_request.milestone = current_milestone
          merge_request.assignee = 'me'
          merge_request.labels.push(new_label)
        end

        Page::MergeRequest::Show.perform do |merge_request|
          expect(merge_request).to have_content(merge_request_title)
          expect(merge_request).to have_content(merge_request_description)
          expect(merge_request).to have_content('Opened just now')
          expect(merge_request).to have_assignee(gitlab_account_username)
          expect(merge_request).to have_label(new_label.title)
        end

        Page::Issuable::Sidebar.perform do |sidebar|
          expect(sidebar).to have_milestone(current_milestone.title)
        end
      end
    end
  end
end
