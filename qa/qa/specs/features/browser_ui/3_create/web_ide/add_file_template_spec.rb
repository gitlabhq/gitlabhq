# frozen_string_literal: true

module QA
  # Failure issue: https://gitlab.com/gitlab-org/quality/staging/issues/46
  context 'Create', :quarantine do
    describe 'Web IDE file templates' do
      include Runtime::Fixtures

      def login
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)
      end

      before(:all) do
        login

        @project = Resource::Project.fabricate! do |project|
          project.name = 'file-template-project'
          project.description = 'Add file templates via the Web IDE'
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

          Page::Project::Show.perform(&:open_web_ide!)
          Page::Project::WebIDE::Edit.perform do |page|
            page.create_new_file_from_template template[:file_name], template[:name]

            expect(page.has_file?(template[:file_name])).to be_truthy
          end

          expect(page).to have_button('Undo')
          expect(page).to have_content(content[0..100])

          Page::Project::WebIDE::Edit.perform(&:commit_changes)

          expect(page).to have_content(template[:file_name])
          expect(page).to have_content(content[0..100])
        end
      end
    end
  end
end
