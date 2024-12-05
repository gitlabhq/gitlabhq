# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Create a new merge request', product_group: :code_review do
      let(:project) { create(:project) }
      let(:merge_request_title) { 'One merge request to rule them all' }
      let(:merge_request_description) { '... to find them, to bring them all, and in the darkness bind them' }

      before do
        Flow::Login.sign_in
      end

      it(
        'creates a basic merge request',
        :smoke, :skip_fips_env, :health_check,
        quarantine: {
          only: { job: 'update-ee-to-ce' },
          issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/412361',
          type: :investigating
        },
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347738'
      ) do
        Resource::MergeRequest.fabricate_via_browser_ui! do |merge_request|
          merge_request.project = project
          merge_request.title = merge_request_title
          merge_request.assignee = 'me'
          merge_request.description = merge_request_description
        end

        Page::MergeRequest::Show.perform do |merge_request|
          expect(merge_request).to have_title(merge_request_title)
          expect(merge_request).to have_description(merge_request_description)
        end
      end

      it(
        'creates a merge request with a milestone and label', :smoke, :health_check,
        quarantine: {
          only: { job: 'update-ee-to-ce' },
          issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/494054',
          type: :investigating
        },
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347762'
      ) do
        gitlab_account_user_name = Runtime::User::Store.test_user.name

        milestone = create(:project_milestone, project: project)

        label = create(:project_label, project: project, title: 'foo::label')

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
          expect(merge_request).to have_assignee(gitlab_account_user_name)
          expect(merge_request).to have_label(label.title)
          expect(merge_request).to have_milestone(milestone.title)
        end
      end
    end
  end
end
