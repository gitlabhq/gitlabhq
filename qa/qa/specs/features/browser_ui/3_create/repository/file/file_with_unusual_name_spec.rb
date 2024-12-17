# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'File with unusual name', product_group: :source_code do
      let(:file_name) { '-un:usually;named#file?.md' }
      let(:project) { create(:project, :with_readme, name: 'unusually-named-file-project') }

      before do
        Flow::Login.sign_in
      end

      context 'when file name starts with a dash and contains hash, semicolon, colon, and question mark' do
        it 'renders repository file tree correctly', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347714' do
          create(:file,
            project: project,
            name: "test-folder/#{file_name}",
            content: "### Heading\n\n[Example link](https://example.com/)")

          project.visit!

          Page::Project::Show.perform do |show|
            show.click_file('test-folder')

            expect(show).to have_file(file_name)

            show.click_file(file_name)

            aggregate_failures 'markdown file contents' do
              expect(show).to have_content('Heading')
              expect(show).to have_content('Example link')
              expect(show).not_to have_content('###')
              expect(show).not_to have_content('https://example.com/')
            end
          end
        end
      end
    end
  end
end
