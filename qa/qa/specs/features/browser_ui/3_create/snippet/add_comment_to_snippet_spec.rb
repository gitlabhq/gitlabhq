# frozen_string_literal: true

module QA
  RSpec.describe 'Create', product_group: :source_code do
    describe 'Adding comments on snippets' do
      let(:comment_author) { Runtime::User::Store.additional_test_user }
      let(:comment_content) { 'Comment 123' }
      let(:edited_comment_content) { 'Nice snippet!' }

      let(:personal_snippet) do
        Resource::Snippet.fabricate! do |snippet|
          snippet.title = 'Personal snippet with a comment'
        end
      end

      let(:project_snippet) do
        Resource::ProjectSnippet.fabricate! do |snippet|
          snippet.title = 'Project snippet with a comment'
        end
      end

      before do
        Flow::Login.sign_in
      end

      shared_examples 'comments on snippets' do |snippet_type, testcase|
        it "adds, edits, and deletes a comment on a #{snippet_type}", testcase: testcase do
          send(snippet_type)

          Page::Main::Menu.perform(&:sign_out)

          Flow::Login.sign_in(as: comment_author)

          send(snippet_type).visit!

          create_comment
          verify_comment_content(comment_author.username, comment_content)

          edit_comment
          verify_comment_content(comment_author.username, edited_comment_content)

          delete_comment
          verify_comment_deleted
        end
      end

      it_behaves_like 'comments on snippets', :personal_snippet, 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347816'
      it_behaves_like 'comments on snippets', :project_snippet, 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347817'

      def create_comment
        Page::Dashboard::Snippet::Show.perform do |snippet|
          snippet.add_comment(comment_content)
        end
      end

      def edit_comment
        Page::Dashboard::Snippet::Show.perform do |snippet|
          snippet.edit_comment(edited_comment_content)
        end
      end

      def delete_comment
        Page::Dashboard::Snippet::Show.perform do |snippet|
          snippet.delete_comment(edited_comment_content)
        end
      end

      def verify_comment_content(author, comment_content)
        Page::Dashboard::Snippet::Show.perform do |snippet|
          expect(snippet).to have_comment_author(author)
          expect(snippet).to have_comment_content(comment_content)
        end
      end

      def verify_comment_deleted
        Page::Dashboard::Snippet::Show.perform do |snippet|
          snippet.within_notes_list do
            expect(snippet).not_to have_content(comment_author.username)
            expect(snippet).not_to have_content(edited_comment_content)
          end
        end
      end
    end
  end
end
