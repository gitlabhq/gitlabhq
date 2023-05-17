# frozen_string_literal: true

# TODO: remove this test when coverage is replaced or deemed irrelevant
module QA
  RSpec.describe 'Create', :skip_live_env, product_group: :ide do
    before do
      skip("Skipped but kept as reference. https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115741#note_1330720944")
    end

    describe 'Upload a file in Web IDE' do
      let(:file_path) { File.join(Runtime::Path.fixtures_path, 'web_ide', file_name) }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'upload-file-project'
          project.initialize_with_readme = true
        end
      end

      before do
        Flow::Login.sign_in

        project.visit!
        Page::Project::Show.perform(&:open_web_ide!)
      end

      context 'when a file with the same name already exists' do
        let(:file_name) { 'README.md' }

        it 'throws an error', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347850' do
          Page::Project::WebIDE::Edit.perform do |ide|
            ide.wait_until_ide_loads
            ide.upload_file(file_path)
          end

          expect(page).to have_content('The name "README.md" is already taken in this directory.')
        end
      end

      context 'when the file is a text file' do
        let(:file_name) { 'text_file.txt' }

        it 'shows the Edit tab with the text',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347852' do
          Page::Project::WebIDE::Edit.perform do |ide|
            ide.wait_until_ide_loads
            ide.upload_file(file_path)

            expect(ide).to have_file(file_name)
            expect(ide).to have_file_addition_icon(file_name)
            expect(ide).to have_text('Simple text')

            ide.commit_changes

            expect(ide).to have_file(file_name)
          end
        end
      end

      context 'when the file is binary' do
        let(:file_name) { 'logo_sample.svg' }

        it 'shows a Download button', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347851' do
          Page::Project::WebIDE::Edit.perform do |ide|
            ide.upload_file(file_path)

            expect(ide).to have_file(file_name)
            expect(ide).to have_file_addition_icon(file_name)
            expect(ide).to have_download_button(file_name)

            ide.commit_changes

            expect(ide).to have_file(file_name)
          end
        end
      end

      context 'when the file is an image' do
        let(:file_name) { 'dk.png' }

        it 'shows an image viewer', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347853' do
          Page::Project::WebIDE::Edit.perform do |ide|
            ide.upload_file(file_path)

            expect(ide).to have_file(file_name)
            expect(ide).to have_file_addition_icon(file_name)
            expect(ide).to have_image_viewer(file_name)

            ide.commit_changes

            expect(ide).to have_file(file_name)
          end
        end
      end
    end
  end
end
