# frozen_string_literal: true

module QA
  context 'Create' do
    describe 'Download merge request patch and diff' do
      before(:context) do
        @merge_request = Resource::MergeRequest.fabricate_via_api! do |merge_request|
          merge_request.title = 'This is a merge request'
          merge_request.description = '... for downloading patches and diffs'
        end
      end

      it 'views the merge request email patches' do
        Flow::Login.sign_in

        @merge_request.visit!
        Page::MergeRequest::Show.perform(&:view_email_patches)

        expect(page.text).to start_with('From')
        expect(page).to have_content('Subject: [PATCH] This is a test commit')
        expect(page).to have_content("diff --git a/#{@merge_request.file_name} b/#{@merge_request.file_name}")
      end

      it 'views the merge request plain diff' do
        Flow::Login.sign_in

        @merge_request.visit!
        Page::MergeRequest::Show.perform(&:view_plain_diff)

        expect(page.text).to start_with("diff --git a/#{@merge_request.file_name} b/#{@merge_request.file_name}")
        expect(page).to have_content('+File Added')
      end
    end
  end
end
