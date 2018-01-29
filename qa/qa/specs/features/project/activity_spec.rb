module QA
  feature 'activity page', :core do
    scenario 'push creates an event in the activity page' do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }

      Factory::Repository::Push.fabricate! do |push|
        push.file_name = 'README.md'
        push.file_content = '# This is a test project'
        push.commit_message = 'Add README.md'
      end

      Page::Menu::Side.act { go_to_activity }

      Page::Project::Activity.act { go_to_push_events }

      expect(page).to have_content('pushed new branch master')
    end
  end
end
