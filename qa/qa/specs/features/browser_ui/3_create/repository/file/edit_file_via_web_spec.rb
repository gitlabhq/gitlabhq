# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    context 'File management' do
      let(:file) { Resource::File.fabricate_via_api! }

      updated_file_content = 'QA Test - Updated file content'
      commit_message_for_update = 'QA Test - Update file'

      before do
        Flow::Login.sign_in
        file.visit!
      end

      it 'user edits a file via the Web', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1094' do
        Page::File::Show.perform(&:click_edit)

        Page::File::Form.perform do |file|
          file.remove_content
          file.add_content(updated_file_content)
          file.add_commit_message(commit_message_for_update)
          file.commit_changes
        end

        Page::File::Show.perform do |file|
          aggregate_failures 'file details' do
            expect(file).to have_notice('Your changes have been successfully committed.')
            expect(file).to have_file_content(updated_file_content)
            expect(file).to have_commit_message(commit_message_for_update)
          end
        end
      end
    end
  end
end
