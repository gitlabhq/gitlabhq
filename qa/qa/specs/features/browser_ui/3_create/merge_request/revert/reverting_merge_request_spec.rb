# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Merged merge request', :requires_admin, product_group: :code_review do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'revert'
        end
      end

      let(:revertible_merge_request) do
        Resource::MergeRequest.fabricate_via_api! do |merge_request|
          merge_request.project = project
        end
      end

      before do
        QA::Support::Helpers::ImportSource.enable(%w[gitlab_project])

        Flow::Login.sign_in
      end

      it 'can be reverted', :can_use_large_setup, testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347709' do
        revertible_merge_request.visit!

        Page::MergeRequest::Show.perform do |merge_request|
          merge_request.merge!
          expect(merge_request).to be_revertible, 'Expected merge request to be in a state to be reverted.'
          merge_request.revert_change!
        end

        Page::MergeRequest::New.perform(&:create_merge_request)

        Page::MergeRequest::Show.perform do |merge_request|
          merge_request.click_diffs_tab
          expect(merge_request).to have_file(revertible_merge_request.file_name)
        end
      end
    end
  end
end
