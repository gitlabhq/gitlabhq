# frozen_string_literal: true

module QA
  RSpec.describe 'Create', feature_category: :web_ide do
    describe 'Upload a file in Web IDE' do
      include_context "Web IDE test prep"
      let(:file_path) { File.absolute_path(File.join('qa', 'fixtures', 'web_ide', file_name)) }
      let(:project) { create(:project, :with_readme, name: 'webide-upload-file-project') }

      before do
        load_web_ide
      end

      shared_examples 'upload a file' do
        it "verifies it successfully uploads and commits to a MR" do
          Page::Project::WebIDE::VSCode.perform do |ide|
            ide.upload_file(file_path)
            Support::Waiter.wait_until { ide.has_pending_changes? }
            ide.commit_and_push_to_new_branch(file_name)

            expect(ide).to have_message(Page::Project::WebIDE::VSCode::COMMIT_SUCCESS_MESSAGE)

            ide.create_merge_request
          end
          # Opens the MR in new tab and verify the file is in the MR
          page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)

          Page::MergeRequest::Show.perform do |merge_request|
            expect(merge_request).to have_content(file_name)
          end
        end
      end

      context 'with a new file', quarantine: {
        issue: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/1603',
        type: :stale
      } do
        context 'when the file is an image',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/390007' do
          let(:file_name) { 'dk.png' }

          it_behaves_like 'upload a file'
        end
      end
    end
  end
end
