# frozen_string_literal: true

module QA
  RSpec.describe 'Create', product_group: :remote_development do
    describe 'Upload a file in Web IDE' do
      let(:file_path) { File.absolute_path(File.join('qa', 'fixtures', 'web_ide', file_name)) }
      let(:project) { create(:project, :with_readme, name: 'webide-upload-file-project') }

      before do
        Flow::Login.sign_in
        project.visit!
        Page::Project::Show.perform(&:open_web_ide!)
        Page::Project::WebIDE::VSCode.perform do |ide|
          ide.wait_for_ide_to_load('README.md')
        end
      end

      context 'when a file with the same name already exists' do
        let(:file_name) { 'README.md' }

        it 'throws an error', :blocking, testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/390005' do
          Page::Project::WebIDE::VSCode.perform do |ide|
            ide.upload_file(file_path)

            expect(ide).to have_message(
              "A file or folder with the name 'README.md' already exists in the destination folder"
            )
          end
        end
      end

      shared_examples 'upload a file' do
        it "verifies it successfully uploads and commits to a MR",
          quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/491469' do
          Page::Project::WebIDE::VSCode.perform do |ide|
            ide.upload_file(file_path)
            Support::Waiter.wait_until { ide.has_pending_changes? }
            ide.commit_and_push_to_new_branch(file_name)

            expect(ide).to have_message('Success! Your changes have been committed.')

            ide.create_merge_request
          end
          # Opens the MR in new tab and verify the file is in the MR
          page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)

          Page::MergeRequest::Show.perform do |merge_request|
            expect(merge_request).to have_content(file_name)
          end
        end
      end

      context 'when the file is a text file', :blocking,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/390006' do
        let(:file_name) { 'text_file.txt' }

        it_behaves_like 'upload a file'
      end

      context 'when the file is an image', :blocking,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/390007' do
        let(:file_name) { 'dk.png' }

        it_behaves_like 'upload a file'
      end
    end
  end
end
