module QA

  feature 'create file in project', :core do

    scenario 'user creates a file' do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act {sign_in_using_credentials}

      Factory::Resource::Project.fabricate! do |project|
        project.name = 'awesome-project'
        project.description = 'create awesome project test'
      end


      Page::Project::Show.act {create_new_file}

      name_of_file = 'My file Name'
      file_content = 'My file content'

      Page::File::New.act do
        add_name_of_file(name_of_file)
        add_file_content(file_content)
        add_commit_message('This is a commit message')
        commit_changes
      end

      expect(page).to have_content('The file has been successfully created.')
      expect(page).to have_content(name_of_file)
      expect(page).to have_content(file_content)

      sleep 10

    end

  end

end