# frozen_string_literal: true

module QA
  RSpec.describe 'Create', :smoke do
    describe 'Personal snippet creation' do
      it 'User creates a personal snippet', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/840' do
        Flow::Login.sign_in

        Page::Main::Menu.perform do |menu|
          menu.go_to_more_dropdown_option(:snippets_link)
        end

        Resource::Snippet.fabricate_via_browser_ui! do |snippet|
          snippet.title = 'Snippet title'
          snippet.description = 'Snippet description'
          snippet.visibility = 'Private'
          snippet.file_name = 'ruby_file.rb'
          snippet.file_content = 'File.read("test.txt").split(/\n/)'
        end

        Page::Dashboard::Snippet::Show.perform do |snippet|
          expect(snippet).to have_snippet_title('Snippet title')
          expect(snippet).to have_snippet_description('Snippet description')
          expect(snippet).to have_visibility_type(/private/i)
          expect(snippet).to have_file_name('ruby_file.rb')
          expect(snippet).to have_file_content('File.read("test.txt").split(/\n/)')
          expect(snippet).to have_syntax_highlighting('ruby')
        end
      end
    end
  end
end
