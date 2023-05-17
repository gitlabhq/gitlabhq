# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Multiple file snippet', :reliable, product_group: :source_code do
      let(:personal_snippet) do
        Resource::Snippet.fabricate_via_api! do |snippet|
          snippet.title = 'Personal snippet to delete file from'
          snippet.file_name = 'Original file name'
          snippet.file_content = 'Original file content'

          snippet.add_files do |files|
            files.append(name: 'Second file name', content: 'Second file content')
          end
        end
      end

      let(:project_snippet) do
        Resource::ProjectSnippet.fabricate_via_api! do |snippet|
          snippet.title = 'Project snippet to delete file from'
          snippet.file_name = 'Original file name'
          snippet.file_content = 'Original file content'

          snippet.add_files do |files|
            files.append(name: 'Second file name', content: 'Second file content')
          end
        end
      end

      before do
        Flow::Login.sign_in
      end

      shared_examples 'deleting file from snippet' do |snippet_type, testcase|
        it "deletes second file from an existing #{snippet_type} to make it single-file", testcase: testcase do
          send(snippet_type).visit!

          Page::Dashboard::Snippet::Show.perform(&:click_edit_button)

          Page::Dashboard::Snippet::Edit.perform do |snippet|
            snippet.click_delete_file(2)
            snippet.save_changes
          end

          Page::Dashboard::Snippet::Show.perform do |snippet|
            aggregate_failures 'file names and contents' do
              expect(snippet).to have_file_name('Original file name')
              expect(snippet).to have_file_content('Original file content')
              expect(snippet).not_to have_file_name('Second file name')
              expect(snippet).not_to have_file_content('Second file content')
            end
          end
        end
      end

      it_behaves_like 'deleting file from snippet', :personal_snippet, 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347728'
      it_behaves_like 'deleting file from snippet', :project_snippet, 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347727'
    end
  end
end
