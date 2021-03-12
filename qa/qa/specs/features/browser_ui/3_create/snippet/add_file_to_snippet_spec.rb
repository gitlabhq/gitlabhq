# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Multiple file snippet' do
      let(:personal_snippet) do
        Resource::Snippet.fabricate_via_api! do |snippet|
          snippet.title = 'Personal snippet to add file to'
          snippet.file_name = 'Original file name'
          snippet.file_content = 'Original file content'
        end
      end

      let(:project_snippet) do
        Resource::ProjectSnippet.fabricate_via_api! do |snippet|
          snippet.title = 'Project snippet to add file to'
          snippet.file_name = 'Original file name'
          snippet.file_content = 'Original file content'
        end
      end

      before do
        Flow::Login.sign_in
      end

      after do
        personal_snippet&.remove_via_api!
        project_snippet&.remove_via_api!
      end

      shared_examples 'adding file to snippet' do |snippet_type|
        it "adds second file to an existing #{snippet_type} to make it multi-file" do
          send(snippet_type).visit!

          Page::Dashboard::Snippet::Show.perform(&:click_edit_button)

          Page::Dashboard::Snippet::Edit.perform do |snippet|
            snippet.click_add_file
            snippet.fill_file_name('Second file name', 2)
            snippet.fill_file_content('Second file content', 2)
            snippet.save_changes
          end

          Page::Dashboard::Snippet::Show.perform do |snippet|
            aggregate_failures 'file names and contents' do
              expect(snippet).to have_file_name('Original file name', 1)
              expect(snippet).to have_file_content('Original file content', 1)
              expect(snippet).to have_file_name('Second file name', 2)
              expect(snippet).to have_file_content('Second file content', 2)
            end
          end
        end
      end

      it_behaves_like 'adding file to snippet', :personal_snippet
      it_behaves_like 'adding file to snippet', :project_snippet
    end
  end
end
