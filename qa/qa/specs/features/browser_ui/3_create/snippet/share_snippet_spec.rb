# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Sharing snippets' do
      let(:snippet) do
        Resource::Snippet.fabricate! do |snippet|
          snippet.title = 'Shared snippet'
          snippet.visibility = 'Public'
          snippet.file_name = 'code.py'
          snippet.file_content = 'code to be shared'
        end
      end

      before do
        Flow::Login.sign_in
      end

      after do
        snippet&.remove_via_api!
      end

      context 'when the snippet is public' do
        it 'can be shared with not signed-in users', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1016' do
          snippet.visit!

          sharing_link = Page::Dashboard::Snippet::Show.perform do |snippet|
            expect(snippet).to have_embed_dropdown
            snippet.get_sharing_link
          end

          Page::Main::Menu.perform(&:sign_out)

          page.visit(sharing_link)

          Page::Dashboard::Snippet::Show.perform do |snippet|
            expect(snippet).to have_snippet_title('Shared snippet')
            expect(snippet).to have_visibility_type(/public/i)
            expect(snippet).to have_file_content('code to be shared')
            expect(snippet).to have_embed_dropdown
          end
        end
      end

      context 'when the snippet is changed to private' do
        it 'does not display Embed/Share dropdown', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1015' do
          snippet.visit!

          Page::Dashboard::Snippet::Show.perform do |snippet|
            expect(snippet).to have_embed_dropdown

            snippet.click_edit_button
          end

          Page::Dashboard::Snippet::Edit.perform do |snippet|
            snippet.change_visibility_to('Private')
            snippet.save_changes
          end

          Page::Dashboard::Snippet::Show.perform do |snippet|
            expect(snippet).not_to have_embed_dropdown
          end
        end
      end
    end
  end
end
