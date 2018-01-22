module QA
  feature 'CI/CD Pipelines', :core, :docker do
    scenario 'user registers a new specific runner' do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }

      Factory::Resource::Runner.fabricate! do |runner|
        runner.perform do |page, runner|
          expect(page).to have_content(runner.name)
          expect(page).to have_online_runner
        end
      end
    end
  end
end
