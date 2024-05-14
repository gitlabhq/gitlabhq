# frozen_string_literal: true

module QA
  RSpec.describe 'Create', :smoke, product_group: :source_code do
    describe 'Personal snippet creation' do
      let(:snippet) do
        Resource::Snippet.fabricate_via_browser_ui! do |snippet|
          snippet.title = 'Snippet title'
          snippet.description = 'Snippet description'
          snippet.visibility = 'Private'
          snippet.file_name = 'ruby_file.rb'
          snippet.file_content = 'File.read("test.txt").split(/\n/)'
        end
      end

      before do
        Flow::Login.sign_in
      end

      after do
        if Runtime::Env.personal_access_tokens_disabled?
          snippet.visit!
          Page::Dashboard::Snippet::Show.perform(&:click_delete_button)
        else
          snippet.remove_via_api!
        end
      end

      it 'user creates a personal snippet', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347799' do
        snippet

        Page::Dashboard::Snippet::Show.perform do |snippet|
          expect(snippet).to have_snippet_title('Snippet title')
          expect(snippet).to have_snippet_description('Snippet description')
          expect(snippet).to have_visibility_description('The snippet is visible only to me.')
          expect(snippet).to have_file_name('ruby_file.rb')
          expect(snippet).to have_file_content('File.read("test.txt").split(/\n/)')
          expect(snippet).to have_syntax_highlighting('ruby')
        end
      end
    end
  end
end
