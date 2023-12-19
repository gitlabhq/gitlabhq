# frozen_string_literal: true

module QA
  RSpec.describe 'Create', :skip_live_env, product_group: :ide do
    describe 'Add first file in Web IDE' do
      let(:project) { create(:project, :with_readme, name: 'webide-create-file-project') }

      before do
        Flow::Login.sign_in
        project.visit!
        Page::Project::Show.perform(&:open_web_ide!)
        Page::Project::WebIDE::VSCode.perform(&:wait_for_ide_to_load)
      end

      context 'when a file with the same name already exists' do
        let(:file_name) { 'README.md' }

        it 'throws an error', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/432899' do
          Page::Project::WebIDE::VSCode.perform do |ide|
            ide.create_new_file(file_name)

            expect(ide)
              .to have_message("A file or folder README.md already exists at this location")
          end
        end
      end

      context 'when user adds a new file' do
        let(:file_name) { 'first_file.txt' }

        it 'shows successfully added and visible in project',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/432898' do
          Page::Project::WebIDE::VSCode.perform do |ide|
            ide.create_new_file(file_name)
            ide.commit_and_push_to_existing_branch(file_name)

            expect(ide).to have_message('Success! Your changes have been committed.')
          end

          project.visit!

          Page::Project::Show.perform do |project|
            expect(project).to have_file(file_name)
          end
        end
      end
    end
  end
end
