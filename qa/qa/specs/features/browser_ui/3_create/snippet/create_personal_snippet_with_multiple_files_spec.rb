# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Multiple file snippet', product_group: :source_code do
      let(:snippet) do
        Resource::Snippet.fabricate_via_browser_ui! do |snippet|
          snippet.title = 'Personal snippet with multiple files'
          snippet.description = 'Snippet description'
          snippet.visibility = 'Private'
          snippet.file_name = 'First file name'
          snippet.file_content = 'First file content'

          snippet.add_files do |files|
            files.append(name: 'Second file name', content: 'Second file content')
            files.append(name: 'Third file name', content: 'Third file content')
          end
        end
      end

      before do
        Flow::Login.sign_in
      end

      it 'creates a personal snippet with multiple files', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347723' do
        snippet

        Page::Dashboard::Snippet::Show.perform do |snippet|
          expect(snippet).to have_snippet_title('Personal snippet with multiple files')
          expect(snippet).to have_snippet_description('Snippet description')
          expect(snippet).to have_visibility_description('The snippet is visible only to me.')
          expect(snippet).to have_file_name('First file name', 1)
          expect(snippet).to have_file_content('First file content', 1)
          expect(snippet).to have_file_name('Second file name', 2)
          expect(snippet).to have_file_content('Second file content', 2)
          expect(snippet).to have_file_name('Third file name', 3)
          expect(snippet).to have_file_content('Third file content', 3)
        end
      end
    end
  end
end
