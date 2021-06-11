# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Snippet index page' do
      let(:personal_snippet_with_single_file) do
        Resource::Snippet.fabricate_via_api! do |snippet|
          snippet.title = "Personal snippet with one file-#{SecureRandom.hex(8)}"
          snippet.visibility = 'Public'
        end
      end

      let(:personal_snippet_with_multiple_files) do
        Resource::Snippet.fabricate_via_api! do |snippet|
          snippet.title = "Personal snippet with multiple files-#{SecureRandom.hex(8)}"
          snippet.visibility = 'Private'
          snippet.file_name = 'First file name'
          snippet.file_content = 'first file content'

          snippet.add_files do |files|
            files.append(name: 'Second file name', content: 'second file content')
            files.append(name: 'Third file name', content: 'third file content')
          end
        end
      end

      let(:project_snippet_with_single_file) do
        Resource::ProjectSnippet.fabricate_via_api! do |snippet|
          snippet.title = "Project snippet with one file-#{SecureRandom.hex(8)}"
          snippet.visibility = 'Private'
        end
      end

      let(:project_snippet_with_multiple_files) do
        Resource::ProjectSnippet.fabricate_via_api! do |snippet|
          snippet.title = "Project snippet with multiple files-#{SecureRandom.hex(8)}"
          snippet.visibility = 'Public'
          snippet.file_name = 'First file name'
          snippet.file_content = 'first file content'

          snippet.add_files do |files|
            files.append(name: 'Second file name', content: 'second file content')
            files.append(name: 'Third file name', content: 'third file content')
          end
        end
      end

      before do
        Flow::Login.sign_in
      end

      after do
        personal_snippet_with_single_file.remove_via_api!
        personal_snippet_with_multiple_files.remove_via_api!
        project_snippet_with_single_file.remove_via_api!
        project_snippet_with_multiple_files.remove_via_api!
      end

      shared_examples 'displaying details on index page' do |snippet_type|
        it "shows correct details of #{snippet_type} including file number" do
          send(snippet_type)
          Page::Main::Menu.perform do |menu|
            menu.go_to_menu_dropdown_option(:snippets_link)
          end

          Page::Dashboard::Snippet::Index.perform do |snippet|
            aggregate_failures 'file content verification' do
              expect(snippet).to have_snippet_title(send(snippet_type).title)
              expect(snippet).to have_visibility_level(send(snippet_type).title, send(snippet_type).visibility)
              expect(snippet).to have_number_of_files(send(snippet_type).title, send(snippet_type).files.count)
            end
          end
        end
      end

      it_behaves_like 'displaying details on index page', :personal_snippet_with_single_file
      it_behaves_like 'displaying details on index page', :personal_snippet_with_multiple_files
      it_behaves_like 'displaying details on index page', :project_snippet_with_single_file
      it_behaves_like 'displaying details on index page', :project_snippet_with_multiple_files
    end
  end
end
