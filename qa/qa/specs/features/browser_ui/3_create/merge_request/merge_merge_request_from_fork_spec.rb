# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Merge request creation from fork', product_group: :code_review do
      let(:merge_request) do
        Resource::MergeRequestFromFork.fabricate_via_browser_ui! do |merge_request|
          merge_request.fork_branch = 'feature-branch'
        end
      end

      before do
        Flow::Login.sign_in
      end

      after do
        merge_request.fork.remove_via_api!
      end

      it 'can merge source branch from fork into upstream repository', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347818' do
        merge_request.visit!

        Page::MergeRequest::Show.perform do |merge_request|
          merge_request.merge!

          expect(merge_request).to be_merged
        end
      end
    end
  end
end
