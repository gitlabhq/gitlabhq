# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Create a new merge request' do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project'
        end
      end

      let(:merge_request_title) { 'One merge request to rule them all' }
      let(:merge_request_description) { '... to find them, to bring them all, and in the darkness bind them' }

      before do
        Flow::Login.sign_in
      end

      it(
        'creates a basic merge request',
        :smoke,
        testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1850'
      ) do
        Resource::MergeRequest.fabricate_via_browser_ui! do |merge_request|
          merge_request.project = project
          merge_request.title = merge_request_title
          merge_request.description = merge_request_description
        end

        Page::MergeRequest::Show.perform do |merge_request|
          expect(merge_request).to have_title(merge_request_title)
          expect(merge_request).to have_description(merge_request_description)
        end
      end

      it(
        'creates a merge request with a milestone and label',
        testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/514'
      ) do
        gitlab_account_username = "@#{Runtime::User.username}"

        milestone = Resource::ProjectMilestone.fabricate_via_api! do |milestone|
          milestone.project = project
        end

        label = Resource::ProjectLabel.fabricate_via_api! do |label|
          label.project = project
          label.title = 'label'
        end

        Resource::MergeRequest.fabricate_via_browser_ui! do |merge_request|
          merge_request.title = merge_request_title
          merge_request.description = merge_request_description
          merge_request.project = project
          merge_request.milestone = milestone
          merge_request.assignee = 'me'
          merge_request.labels.push(label)
        end

        Page::MergeRequest::Show.perform do |merge_request|
          expect(merge_request).to have_title(merge_request_title)
          expect(merge_request).to have_description(merge_request_description)
          expect(merge_request).to have_assignee(gitlab_account_username)
          expect(merge_request).to have_label(label.title)
          expect(merge_request).to have_milestone(milestone.title)
        end
      end
    end
  end
end
