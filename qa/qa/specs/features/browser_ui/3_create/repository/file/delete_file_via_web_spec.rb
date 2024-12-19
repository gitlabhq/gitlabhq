# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'File management', product_group: :source_code do
      let(:file) { create(:file) }

      commit_message_for_delete = 'QA Test - Delete file'

      before do
        Flow::Login.sign_in
        file.visit!
      end

      it 'user deletes a file via the Web', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347731' do
        Page::File::Show.perform do |file|
          file.click_delete
          file.add_commit_message(commit_message_for_delete)
        end

        Page::File::Edit.perform(&:commit_changes_through_modal)

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
