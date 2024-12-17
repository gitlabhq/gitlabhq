# frozen_string_literal: true

module QA
  RSpec.describe 'Create', product_group: :source_code do
    describe 'Multiple file snippet' do
      let(:personal_snippet) do
        create(:project_snippet,
          title: 'Personal snippet to add file to',
          file_name: 'Original file name',
          file_content: 'Original file content')
      end

      let(:project_snippet) do
        create(:project_snippet,
          title: 'Project snippet to add file to',
          file_name: 'Original file name',
          file_content: 'Original file content')
      end

      before do
        Flow::Login.sign_in
      end

      shared_examples 'adding file to snippet' do |snippet_type, testcase|
        it "adds second file to an existing #{snippet_type} to make it multi-file", testcase: testcase do
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

      it_behaves_like 'adding file to snippet', :personal_snippet, 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347845'
      it_behaves_like 'adding file to snippet', :project_snippet, 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347846'
    end
  end
end
