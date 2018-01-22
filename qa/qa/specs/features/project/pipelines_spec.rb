module QA
  feature 'CI/CD Pipelines', :core, :docker do
    scenario 'user registers a new specific runner' do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }

      Factory::Resource::Runner.fabricate! do |runner|
        runner.name = 'my-qa-runner'

        runner.perform do |page|
          expect(page).to have_content('my-qa-runner')
          expect(page).to have_css('.runner-status-online')
        end
      end
    end
  end
end
