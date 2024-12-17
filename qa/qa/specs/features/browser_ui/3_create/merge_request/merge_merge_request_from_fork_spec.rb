# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Merge request creation from fork', :requires_admin, product_group: :code_review do
      let!(:user) { create(:user, :with_personal_access_token) }
      let!(:fork) { create(:fork, user: user) }
      let!(:merge_request) { create(:merge_request_from_fork, fork: fork) }

      before do
        Flow::Login.sign_in
      end

      it 'can merge source branch from fork into upstream repository',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347818' do
        merge_request.visit!

        Page::MergeRequest::Show.perform do |merge_request|
          merge_request.merge!

          expect(merge_request).to be_merged
        end
      end
    end
  end
end
