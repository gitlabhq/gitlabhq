# frozen_string_literal: true

module QA
  RSpec.describe 'Create', quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/332588', type: :investigating } do
    describe 'Merge request creation from fork' do
      # TODO: Please add this back to :smoke suite as soon as https://gitlab.com/gitlab-org/gitlab/-/issues/332588 is addressed
      it 'can merge feature branch fork to mainline', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1701' do
        merge_request = Resource::MergeRequestFromFork.fabricate_via_browser_ui! do |merge_request|
          merge_request.fork_branch = 'feature-branch'
        end

        Flow::Login.while_signed_in do
          merge_request.visit!

          Page::MergeRequest::Show.perform do |merge_request|
            merge_request.merge!

            expect(merge_request).to have_content('The changes were merged')
          end
        end
      end
    end
  end
end
