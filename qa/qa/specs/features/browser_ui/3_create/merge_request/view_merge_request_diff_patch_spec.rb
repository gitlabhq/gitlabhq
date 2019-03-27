# frozen_string_literal: true

module QA
  context 'Create' do
    describe 'Download merge request patch and diff' do
      before(:context) do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        @merge_request = Resource::MergeRequest.fabricate! do |merge_request|
          merge_request.title = 'This is a merge request'
          merge_request.description = 'For downloading patches and diffs'
        end
      end

      it 'user views merge request email patches' do
        @merge_request.visit!
        Page::MergeRequest::Show.perform(&:view_email_patches)

        expect(page.text).to start_with('From')
        expect(page).to have_content('Subject: [PATCH] This is a test commit')
        expect(page).to have_content('diff --git a/added_file.txt b/added_file.txt')
      end

      it 'user views merge request plain diff' do
        @merge_request.visit!
        Page::MergeRequest::Show.perform(&:view_plain_diff)

        expect(page.text).to start_with('diff --git a/added_file.txt b/added_file.txt')
        expect(page).to have_content('+File Added')
      end
    end
  end
end
