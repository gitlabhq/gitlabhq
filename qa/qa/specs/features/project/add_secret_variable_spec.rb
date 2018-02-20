module QA
  feature 'secret variables support', :core do
    scenario 'user adds a secret variable' do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }

      Factory::Resource::SecretVariable.fabricate! do |resource|
        resource.key = 'VARIABLE_KEY'
        resource.value = 'some secret variable'
      end

      Page::Project::Settings::CICD.perform do |settings|
        settings.expand_secret_variables do |page|
          expect(page).to have_field(with: 'VARIABLE_KEY')
          expect(page).not_to have_field(with: 'some secret variable')

          page.reveal_variables

          expect(page).to have_field(with: 'some secret variable')
        end
      end
    end
  end
end
