module QA
  feature 'create file in project', :core do
    scenario 'user creates a file' do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act {sign_in_using_credentials}

      file_name = 'QA Test - File name'
      file_content = 'QA Test - File content'
      commit_message = 'QA Test - Commit message'

      Factory::Resource::File.fabricate! do |file|
        file.name = file_name
        file.content = file_content
        file.commit_message = commit_message
      end

      expect(page).to have_content('The file has been successfully created.')
      expect(page).to have_content(file_name)
      expect(page).to have_content(file_content)
      expect(page).to have_content(commit_message)

    end

  end

end