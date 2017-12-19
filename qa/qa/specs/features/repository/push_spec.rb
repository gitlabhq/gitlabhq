module QA
  feature 'push code to repository', :core do
    context 'with regular account over http' do
      scenario 'user pushes code to the repository'  do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.act { sign_in_using_credentials }

        Factory::Resource::Project.fabricate! do |scenario|
          scenario.name = 'project_with_code'
          scenario.description = 'project with repository'
        end

        Factory::Repository::Push.fabricate! do |scenario|
          scenario.file_name = 'README.md'
          scenario.file_content = '# This is test project'
          scenario.commit_message = 'Add README.md'
        end

        Page::Project::Show.act do
          wait_for_push
          refresh
        end

        expect(page).to have_content('README.md')
        expect(page).to have_content('This is test project')
      end
    end
  end
end
