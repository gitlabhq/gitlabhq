# frozen_string_literal: true

module QA
  context 'Create', :smoke do
    describe 'Snippet creation' do
      it 'User creates a snippet' do
        Flow::Login.sign_in

        Page::Main::Menu.perform(&:go_to_snippets)

        Resource::Snippet.fabricate_via_browser_ui! do |snippet|
          snippet.title = 'Snippet title'
          snippet.description = 'Snippet description'
          snippet.visibility = 'Private'
          snippet.file_name = 'New snippet file name'
          snippet.file_content = 'Snippet file text'
        end

        Page::Dashboard::Snippet::Show.perform do |snippet|
          expect(snippet).to have_snippet_title('Snippet title')
          expect(snippet).to have_snippet_description('Snippet description')
          expect(snippet).to have_visibility_type('Private')
          expect(snippet).to have_file_name('New snippet file name')
          expect(snippet).to have_file_content('Snippet file text')
        end
      end
    end
  end
end
