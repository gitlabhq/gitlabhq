# frozen_string_literal: true

module QA
  context 'Create' do
    describe 'File templates' do
      include Runtime::Fixtures

      def login
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)
      end

      before(:all) do
        login

        @project = Resource::Project.fabricate! do |project|
          project.name = 'file-template-project'
          project.description = 'Add file templates via the Files view'
          project.initialize_with_readme = true
        end

        Page::Main::Menu.perform(&:sign_out)
      end

      templates = [
        {
          file_name: '.gitignore',
          name: 'Android',
          api_path: 'gitignores',
          api_key: 'Android'
        },
        {
          file_name: '.gitlab-ci.yml',
          name: 'Julia',
          api_path: 'gitlab_ci_ymls',
          api_key: 'Julia'
        },
        {
          file_name: 'Dockerfile',
          name: 'Python',
          api_path: 'dockerfiles',
          api_key: 'Python'
        },
        {
          file_name: 'LICENSE',
          name: 'Mozilla Public License 2.0',
          api_path: 'licenses',
          api_key: 'mpl-2.0'
        }
      ]

      templates.each do |template|
        it "user adds #{template[:file_name]} via file template #{template[:name]}" do
          content = fetch_template_from_api(template[:api_path], template[:api_key])

          login
          @project.visit!

          Page::Project::Show.perform(&:create_new_file!)
          Page::File::Form.perform do |page|
            page.select_template template[:file_name], template[:name]
          end

          expect(page).to have_content('Template applied')
          expect(page).to have_button('Undo')
          expect(page).to have_content(content[0..100])

          Page::File::Form.perform(&:commit_changes)

          expect(page).to have_content('The file has been successfully created.')
          expect(page).to have_content(template[:file_name])
          expect(page).to have_content('Add new file')
          expect(page).to have_content(content[0..100])
        end
      end
    end
  end
end
