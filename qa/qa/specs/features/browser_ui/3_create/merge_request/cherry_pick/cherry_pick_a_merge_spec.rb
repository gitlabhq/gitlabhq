# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Cherry picking from a merge request', :smoke, product_group: :code_review do
      let(:project) { create(:project, :with_readme) }
      let(:feature_mr) { create(:merge_request, project: project, target_branch: 'development') }

      before do
        Flow::Login.sign_in
      end

      it 'creates a merge request', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347684' do
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
