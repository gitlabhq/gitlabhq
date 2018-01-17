module QA
  feature 'create a new project', :core do
    scenario 'user creates a new project' do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }

      created_project = Factory::Resource::Project.fabricate! do |project|
        project.name = 'awesome-project'
        project.description = 'create awesome project test'
      end

      expect(created_project.name).to match /^awesome-project-\h{16}$/

      expect(page).to have_content(
        /Project \S?awesome-project\S+ was successfully created/
      )

      expect(page).to have_content('create awesome project test')
      expect(page).to have_content('The repository for this project is empty')
    end
  end
end
