# frozen_string_literal: true

module QA
  RSpec.describe 'Create', product_group: :remote_development, feature_category: :web_ide do
    describe 'Upload a file in Web IDE' do
      include_context "Web IDE test prep"
      let(:file_path) { File.absolute_path(File.join('qa', 'fixtures', 'web_ide', file_name)) }
      let(:project) { create(:project, :with_readme, name: 'webide-upload-file-project') }

      before do
        load_web_ide
      end

      context 'when a file with the same name already exists' do
        let(:file_name) { 'README.md' }

        it 'throws an error', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/390005' do
          Page::Project::WebIDE::VSCode.perform do |ide|
            ide.upload_file(file_path)

            expect(ide).to have_message(
              "A file or folder with the name 'README.md' already exists in the destination folder"
            )
          end
        end
      end

      shared_examples 'upload a file' do
        it "verifies it successfully uploads and commits to a MR" do
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

      context 'when the file is a text file',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/390006' do
        let(:file_name) { 'text_file.txt' }

        it_behaves_like 'upload a file'
      end

      context 'when the file is an image',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/390007' do
        let(:file_name) { 'dk.png' }

        it_behaves_like 'upload a file'
      end
    end
  end
end
