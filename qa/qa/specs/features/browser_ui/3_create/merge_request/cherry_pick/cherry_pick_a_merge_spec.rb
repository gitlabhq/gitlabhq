# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Cherry picking from a merge request' do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project'
          project.initialize_with_readme = true
        end
      end

      let(:feature_mr) do
        Resource::MergeRequest.fabricate_via_api! do |merge_request|
          merge_request.project = project
          merge_request.target_branch = 'development'
          merge_request.target_new_branch = true
        end
      end

      before do
        Flow::Login.sign_in
      end

      it 'creates a merge request', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1616' do
        feature_mr.visit!

        Page::MergeRequest::Show.perform do |merge_request|
          merge_request.merge!
          merge_request.cherry_pick!
        end

        Page::MergeRequest::New.perform(&:create_merge_request)

        Page::MergeRequest::Show.perform do |merge_request|
          merge_request.click_diffs_tab
          expect(merge_request).to have_file(feature_mr.file_name)
        end
      end
    end
  end
end
