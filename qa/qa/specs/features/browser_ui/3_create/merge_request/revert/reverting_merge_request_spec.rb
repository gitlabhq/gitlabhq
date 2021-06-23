# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Merged merge request' do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'revert'
        end
      end

      let(:revertable_merge_request) do
        Resource::MergeRequest.fabricate_via_api! do |merge_request|
          merge_request.project = project
        end
      end

      before do
        Flow::Login.sign_in
      end

      it 'can be reverted', :can_use_large_setup, testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1745' do
        revertable_merge_request.visit!

        Page::MergeRequest::Show.perform do |merge_request|
          merge_request.merge!
          merge_request.revert_change!
        end

        Page::MergeRequest::New.perform(&:create_merge_request)

        Page::MergeRequest::Show.perform do |merge_request|
          merge_request.click_diffs_tab
          expect(merge_request).to have_file(revertable_merge_request.file_name)
        end
      end
    end
  end
end
