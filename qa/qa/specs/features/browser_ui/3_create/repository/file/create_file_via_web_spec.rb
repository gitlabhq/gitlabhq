# frozen_string_literal: true

module QA
  RSpec.describe 'Create', product_group: :source_code do
    describe 'File management' do
      file_name = 'QA Test - File name'
      file_content = 'QA Test - File content'
      commit_message_for_create = 'QA Test - Create new file'

      before do
        Flow::Login.sign_in
      end

      it 'user creates a file via the Web', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347729' do
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
      end
    end
  end
end
