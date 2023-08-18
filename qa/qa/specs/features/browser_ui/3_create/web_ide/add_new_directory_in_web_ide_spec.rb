# frozen_string_literal: true

module QA
  RSpec.describe 'Create', product_group: :ide,
    quarantine: {
      only: { job: 'slow-network' },
      issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/387609',
      type: :flaky
    } do
    describe 'Add a directory in Web IDE' do
      let(:project) { create(:project, :with_readme, name: 'add-directory-project') }

      before do
        Flow::Login.sign_in
        project.visit!
      end

      context 'when a directory with the same name already exists' do
        let(:directory_name) { 'first_directory' }

        before do
          Resource::Repository::Commit.fabricate_via_api! do |commit|
            commit.project = project
            commit.add_files(
              [
                {
                  file_path: 'first_directory/test_file.txt',
                  content: "Test file content"
                }
              ])
          end
          project.visit!
        end

        it 'throws an error', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/386760' do
          Page::Project::Show.perform(&:open_web_ide!)
          Page::Project::WebIDE::VSCode.perform do |ide|
            ide.wait_for_ide_to_load
            ide.create_new_folder(directory_name)
            ide.has_message?('A file or folder first_directory already exists at this location.')
          end
        end
      end

      context 'when user adds a new empty directory' do
        let(:directory_name) { 'new_empty_directory' }

        before do
          Page::Project::Show.perform(&:open_web_ide!)
        end

        it 'shows successfully but not able to be committed',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/386761' do
          Page::Project::WebIDE::VSCode.perform do |ide|
            ide.wait_for_ide_to_load
            ide.create_new_folder(directory_name)
            ide.commit_toggle(directory_name)
            ide.has_message?('No changes found. Not able to commit.')
          end
        end
      end
    end
  end
end
