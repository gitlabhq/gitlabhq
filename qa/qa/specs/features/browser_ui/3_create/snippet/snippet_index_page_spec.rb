# frozen_string_literal: true

module QA
  RSpec.describe 'Create', product_group: :source_code do
    describe 'Snippet index page' do
      let(:personal_snippet_with_single_file) do
        create(:snippet, title: "Personal snippet with one file-#{SecureRandom.hex(8)}")
      end

      let(:personal_snippet_with_multiple_files) do
        create(:snippet,
          :private,
          title: "Personal snippet with multiple files-#{SecureRandom.hex(8)}",
          file_name: 'First file name',
          file_content: 'first file content',
          files: [
            { name: 'Second file name', content: 'second file content' },
            { name: 'Third file name', content: 'third file content' }
          ])
      end

      let(:project_snippet_with_single_file) do
        create(:project_snippet, :private, title: "Project snippet with one file-#{SecureRandom.hex(8)}")
      end

      let(:project_snippet_with_multiple_files) do
        create(:project_snippet,
          title: "Project snippet with multiple files-#{SecureRandom.hex(8)}",
          file_name: 'First file name',
          file_content: 'first file content',
          files: [
            { name: 'Second file name', content: 'second file content' },
            { name: 'Third file name', content: 'third file content' }
          ])
      end

      before do
        Flow::Login.sign_in
      end

      shared_examples 'displaying details on index page' do |snippet_type, testcase|
        it "shows correct details of #{snippet_type} including file number", testcase: testcase do
          send(snippet_type)
          Page::Main::Menu.perform(&:go_to_snippets)

          Page::Dashboard::Snippet::Index.perform do |snippet|
            aggregate_failures 'file content verification' do
              expect(snippet).to have_snippet_title(send(snippet_type).title)
              expect(snippet).to have_visibility_level(send(snippet_type).title, send(snippet_type).visibility)
              expect(snippet).to have_number_of_files(send(snippet_type).title, send(snippet_type).files.count)
            end
          end
        end
      end

      it_behaves_like 'displaying details on index page', :personal_snippet_with_single_file, 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347717'
      it_behaves_like 'displaying details on index page', :personal_snippet_with_multiple_files, 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347720'
      it_behaves_like 'displaying details on index page', :project_snippet_with_single_file, 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347718'
      it_behaves_like 'displaying details on index page', :project_snippet_with_multiple_files, 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347719'
    end
  end
end
