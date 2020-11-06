# frozen_string_literal: true

module QA
  include HaveFileMatcher

  RSpec.describe 'Create' do
    describe 'Files management' do
      it 'user creates, edits and deletes a file via the Web', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/451' do
        Flow::Login.sign_in

        # Create
        file_name = 'QA Test - File name'
        file_content = 'QA Test - File content'
        commit_message_for_create = 'QA Test - Create new file'

        Resource::File.fabricate_via_browser_ui! do |file|
          file.name = file_name
          file.content = file_content
          file.commit_message = commit_message_for_create
        end

        Page::File::Show.perform do |file|
          aggregate_failures 'file details' do
            expect(file).to have_file(file_name)
            expect(file).to have_file_content(file_content)
            expect(file).to have_commit_message(commit_message_for_create)
          end
        end

        # Edit
        updated_file_content = 'QA Test - Updated file content'
        commit_message_for_update = 'QA Test - Update file'

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

        # Delete
        commit_message_for_delete = 'QA Test - Delete file'

        Page::File::Show.perform do |file|
          file.click_delete
          file.add_commit_message(commit_message_for_delete)
          file.click_delete_file
        end

        Page::Project::Show.perform do |project|
          aggregate_failures 'file details' do
            expect(project).to have_notice('The file has been successfully deleted.')
            expect(project).to have_commit_message(commit_message_for_delete)
            expect(project).not_to have_file(file_name)
          end
        end
      end
    end
  end
end
