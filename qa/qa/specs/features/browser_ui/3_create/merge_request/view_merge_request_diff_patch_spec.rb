# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Download merge request patch and diff', :requires_admin, product_group: :code_review do
      let(:merge_request) do
        create(:merge_request, title: 'This is a merge request', description: '... for downloading patches and diffs')
      end

      before do
        Flow::Login.sign_in
        merge_request.visit!
      end

      it 'views the merge request patches', :can_use_large_setup, testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347742' do
        Page::MergeRequest::Show.perform(&:view_email_patches)

        expect(page.text).to start_with('From')
        expect(page).to have_content('Subject: [PATCH] This is a test commit')
        expect(page).to have_content("diff --git a/#{merge_request.file_name} b/#{merge_request.file_name}")
      end

      it 'views the merge request plain diff', :can_use_large_setup, testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347743' do
        Page::MergeRequest::Show.perform(&:view_plain_diff)

        expect(page.text).to start_with('diff')
        expect(page).to have_content("diff --git a/#{merge_request.file_name} b/#{merge_request.file_name}")
        expect(page).to have_content('+File Added')
      end
    end
  end
end
