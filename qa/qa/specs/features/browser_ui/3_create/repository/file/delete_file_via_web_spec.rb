# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    context 'File management' do
      let(:file) { Resource::File.fabricate_via_api! }

      commit_message_for_delete = 'QA Test - Delete file'

      before do
        Flow::Login.sign_in
        file.visit!
      end

      it 'user deletes a file via the Web', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1095' do
        Page::File::Show.perform do |file|
          file.click_delete
          file.add_commit_message(commit_message_for_delete)
          file.click_delete_file
        end

        Page::Project::Show.perform do |project|
          aggregate_failures 'file details' do
            expect(project).to have_notice('The file has been successfully deleted.')
            expect(project).to have_commit_message(commit_message_for_delete)
            expect(project).not_to have_file(file.name)
          end
        end
      end
    end
  end
end
