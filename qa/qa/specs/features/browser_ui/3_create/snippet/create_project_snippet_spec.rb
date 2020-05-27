# frozen_string_literal: true

module QA
  context 'Create' do # to be converted to a smoke test once proved to be stable
    describe 'Project snippet creation' do
      it 'User creates a project snippet' do
        Flow::Login.sign_in

        Resource::ProjectSnippet.fabricate_via_browser_ui! do |snippet|
          snippet.title = 'Project snippet'
          snippet.description = ' '
          snippet.visibility = 'Internal'
          snippet.file_name = 'markdown_file.md'
          snippet.file_content = "### Snippet heading\n\n[Gitlab link](https://gitlab.com/)"
        end

        Page::Dashboard::Snippet::Show.perform do |snippet|
          expect(snippet).to have_snippet_title('Project snippet')
          expect(snippet).to have_no_snippet_description
          expect(snippet).to have_visibility_type(/internal/i)
          expect(snippet).to have_file_name('markdown_file.md')
          expect(snippet).to have_file_content('Snippet heading')
          expect(snippet).to have_file_content('Gitlab link')
          expect(snippet).not_to have_file_content('###')
          expect(snippet).not_to have_file_content('https://gitlab.com/')
        end
      end
    end
  end
end
