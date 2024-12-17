# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'new merge request from the event notification',
      product_group: :code_review do
      let(:branch_name) { "merge-request-test-#{SecureRandom.hex(8)}" }
      let(:title) { "Merge from push event notification test #{SecureRandom.hex(8)}" }
      let(:project) { create(:project, :with_readme) }

      before do
        Flow::Login.sign_in
      end

      it(
        'after a push via the git CLI creates a merge request',
        quarantine: {
          issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/442691',
          type: :flaky
        },
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/360489'
      ) do
        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.branch_name = branch_name
        end

        project.visit!
        Page::Project::Show.perform(&:new_merge_request)
        Page::MergeRequest::New.perform do |merge_request|
          merge_request.fill_title(title)
          merge_request.create_merge_request
        end

        Page::MergeRequest::Show.perform do |merge_request|
          expect(merge_request).to have_title(title)
        end
      end

      it(
        'after a push via the API creates a merge request',
        quarantine: {
          issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/403182',
          type: :flaky
        },
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/360490'
      ) do
        commit = create(:commit,
          project: project,
          branch: branch_name,
          start_branch: project.default_branch,
          actions: [
            { action: 'create', file_path: "file-#{SecureRandom.hex(8)}.txt", content: 'MR init' }
          ])

        project.wait_for_push(commit.commit_message)

        project.visit!
        Page::Project::Show.perform(&:new_merge_request)
        Page::MergeRequest::New.perform do |merge_request|
          merge_request.fill_title(title)
          merge_request.create_merge_request
        end

        Page::MergeRequest::Show.perform do |merge_request|
          expect(merge_request).to have_title(title)
        end
      end
    end
  end
end
