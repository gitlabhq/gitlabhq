# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'File with unusual name' do
      let(:file_name) { '-un:usually;named#file?.md' }
      let(:project) do
        Resource::Project.fabricate_via_api! do |resource|
          resource.name = 'unusually-named-file-project'
          resource.initialize_with_readme = true
        end
      end

      before do
        Flow::Login.sign_in
      end

      context 'when file name starts with a dash and contains hash, semicolon, colon, and question mark' do
        it 'renders repository file tree correctly', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1779' do
          Resource::File.fabricate_via_api! do |file|
            file.project = project
            file.commit_message = 'Add new file'
            file.name = "test-folder/#{file_name}"
            file.content = "### Heading\n\n[Gitlab link](https://gitlab.com/)"
          end

          project.visit!

          Page::Project::Show.perform do |show|
            show.click_file('test-folder')

            expect(show).to have_file(file_name)

            show.click_file(file_name)

            aggregate_failures 'markdown file contents' do
              expect(show).to have_content('Heading')
              expect(show).to have_content('Gitlab link')
              expect(show).not_to have_content('###')
              expect(show).not_to have_content('https://gitlab.com/')
            end
          end
        end
      end
    end
  end
end
