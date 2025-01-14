# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'File management', product_group: :source_code do
      let(:file) { create(:file) }

      updated_file_content = 'QA Test - Updated file content'
      commit_message_for_update = 'QA Test - Update file'

      before do
        Flow::Login.sign_in
        file.visit!
      end

      it 'user edits a file via the Web', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347730' do
        Page::File::Show.perform(&:click_edit)

        Page::File::Form.perform do |file|
          file.remove_content
          file.add_content(updated_file_content)
          file.click_commit_changes_in_header
          file.add_commit_message(commit_message_for_update)
          file.commit_changes_through_modal
        end

        Page::File::Show.perform do |file|
          aggregate_failures 'file details' do
            expect(file).to have_notice('Your changes have been committed successfully.')
            expect(file).to have_file_content(updated_file_content)
            expect(file).to have_commit_message(commit_message_for_update)
          end
        end
      end
    end
  end
end
