# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Multiple file snippet' do
      let(:first_file_content) { 'First file content' }
      let(:second_file_content) { 'Second file content' }
      let(:third_file_content) { 'Third file content' }

      let(:personal_snippet) do
        Resource::Snippet.fabricate_via_api! do |snippet|
          snippet.title = 'Personal snippet to copy file contents from'
          snippet.file_name = 'First file name'
          snippet.file_content = first_file_content

          snippet.add_files do |files|
            files.append(name: 'Second file name', content: second_file_content)
            files.append(name: 'Third file name', content: third_file_content)
          end
        end
      end

      let(:project_snippet) do
        Resource::ProjectSnippet.fabricate_via_api! do |snippet|
          snippet.title = 'Project snippet to copy file contents from'
          snippet.file_name = 'First file name'
          snippet.file_content = first_file_content

          snippet.add_files do |files|
            files.append(name: 'Second file name', content: second_file_content)
            files.append(name: 'Third file name', content: third_file_content)
          end
        end
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

      after do
        personal_snippet&.remove_via_api!
        project_snippet&.remove_via_api!
      end

      shared_examples 'copying snippet file contents' do |snippet_type|
        it "copies file contents of a multi-file #{snippet_type} to a comment and verifies them" do
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

      it_behaves_like 'copying snippet file contents', :personal_snippet
      it_behaves_like 'copying snippet file contents', :project_snippet
    end
  end
end
