# frozen_string_literal: true

module QA
  RSpec.describe 'Create', product_group: :source_code do # to be converted to a smoke test once proved to be stable
    describe 'Project snippet creation' do
      let(:snippet) do
        Resource::ProjectSnippet.fabricate_via_browser_ui! do |snippet|
          snippet.title = 'Project snippet'
          snippet.description = ' '
          snippet.visibility = 'Private'
          snippet.file_name = 'markdown_file.md'
          snippet.file_content = "### Snippet heading\n\n[Example link](https://example.com/)"
        end
      end

      before do
        Flow::Login.sign_in
      end

      it 'user creates a project snippet', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347798' do
        snippet

        Page::Dashboard::Snippet::Show.perform do |snippet|
          expect(snippet).to have_snippet_title('Project snippet')
          expect(snippet).not_to have_snippet_description
          expect(snippet).to have_visibility_description('The snippet is visible only to project members.')
          expect(snippet).to have_file_name('markdown_file.md')
          expect(snippet).to have_file_content('Snippet heading')
          expect(snippet).to have_file_content('Example link')
          expect(snippet).not_to have_file_content('###')
          expect(snippet).not_to have_file_content('https://example.com/')
        end
      end
    end
  end
end
