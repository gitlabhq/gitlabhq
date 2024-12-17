# frozen_string_literal: true

module QA
  RSpec.describe 'Create', product_group: :source_code do
    describe 'Multiple file snippet' do
      let(:first_file_content) { 'First file content' }
      let(:second_file_content) { 'Second file content' }
      let(:third_file_content) { 'Third file content' }

      let(:personal_snippet) do
        create(:project_snippet,
          title: 'Personal snippet to copy file contents from',
          file_name: 'First file name',
          file_content: first_file_content,
          files: [
            { name: 'Second file name', content: second_file_content },
            { name: 'Third file name', content: third_file_content }
          ])
      end

      let(:project_snippet) do
        create(:project_snippet,
          title: 'Project snippet to copy file contents from',
          file_name: 'First file name',
          file_content: first_file_content,
          files: [
            { name: 'Second file name', content: second_file_content },
            { name: 'Third file name', content: third_file_content }
          ])
      end

      let(:files) do
        [
          {
            number: 1,
            content: first_file_content
          },
          {
            number: 2,
            content: second_file_content
          },
          {
            number: 3,
            content: third_file_content
          }
        ]
      end

      before do
        Flow::Login.sign_in
      end

      shared_examples 'copying snippet file contents' do |snippet_type, testcase|
        it "copies a multi-file #{snippet_type} to a comment and verifies them", testcase: testcase do
          send(snippet_type).visit!

          files.each do |files|
            Page::Dashboard::Snippet::Show.perform do |snippet|
              snippet.copy_file_contents_to_comment(files[:number])
              expect(snippet).to have_comment_content(files[:content])
              snippet.delete_comment(files[:content])
            end
          end
        end
      end

      it_behaves_like 'copying snippet file contents', :personal_snippet, 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347849'
      it_behaves_like 'copying snippet file contents', :project_snippet, 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347848'
    end
  end
end
