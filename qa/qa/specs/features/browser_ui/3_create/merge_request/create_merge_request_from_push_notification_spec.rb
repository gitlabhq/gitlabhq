# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Create a new merge request from the event notification after a push', product_group: :code_review do
      let(:branch_name) { "merge-request-test-#{SecureRandom.hex(8)}" }
      let(:title) { "Merge from push event notification test #{SecureRandom.hex(8)}" }
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.initialize_with_readme = true
        end
      end

      before do
        Flow::Login.sign_in
      end

      it(
        'creates a merge request after a push via the git CLI',
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
        'creates a merge request after a push via the API',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/360490'
      ) do
        commit = Resource::Repository::Commit.fabricate_via_api! do |resource|
          resource.project = project
          resource.add_files([{ 'file_path': "file-#{SecureRandom.hex(8)}.txt", 'content': 'MR init' }])
          resource.branch = branch_name
          resource.start_branch = project.default_branch
        end
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
