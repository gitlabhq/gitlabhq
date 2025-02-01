# frozen_string_literal: true

module QA
  RSpec.describe 'Create', product_group: :remote_development, feature_category: :web_ide do
    describe 'Add a directory in Web IDE' do
      include_context 'Web IDE test prep'
      let(:project) { create(:project, :with_readme, name: 'webide-add-directory-project') }

      context 'when a directory with the same name already exists' do
        let(:directory_name) { 'first_directory' }

        before do
          create(:commit, project: project, actions: [
            { action: 'create', file_path: 'first_directory/test_file.txt', content: 'Test file content' }
          ])

          project.visit!
          Page::Project::Show.perform(&:open_web_ide!)
          Page::Project::WebIDE::VSCode.perform do |ide|
            ide.wait_for_ide_to_load('README.md')
          end
        end

        it 'throws an error', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/386760' do
          Page::Project::WebIDE::VSCode.perform do |ide|
            ide.create_new_folder(directory_name)

            expect(ide).to have_message('A file or folder first_directory already exists at this location.')
          end
        end
      end

      context 'when user adds a new empty directory' do
        let(:directory_name) { 'new_empty_directory' }

        before do
          Page::Project::Show.perform(&:open_web_ide!)
          Page::Project::WebIDE::VSCode.perform(&:wait_for_ide_to_load)
        end

        it 'shows successfully but not able to be committed',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/386761' do
          Page::Project::WebIDE::VSCode.perform do |ide|
            ide.create_new_folder(directory_name)
            ide.commit_toggle(directory_name)

            expect(ide).to have_message('No changes found. Not able to commit.')
          end
        end
      end
    end
  end
end
