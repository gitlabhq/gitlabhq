module QA
  feature 'add deploy key', :core do
    before do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }

      Factory::Resource::Project.fabricate! do |scenario|
        scenario.name = 'project-to-deploy'
        scenario.description = 'project for adding deploy key test'
      end

      Page::Project::Show.act do
        click_repository_setting
      end
    end

    given(:deploy_key_title) { 'deploy key title' }
    given(:deploy_key_data) { Runtime::User.ssh_key }

    scenario 'user adds a deploy key' do
      Page::Project::Settings::DeployKeys.perform do |deploy_key|
        deploy_key.fill_new_deploy_key_title(deploy_key_title)
        deploy_key.fill_new_deploy_key_key(deploy_key_data)

        deploy_key.add_key
      end

      Page::Project::Settings::DeployKeys.perform do |deploy_key|
        expect(deploy_key).to have_key_title(deploy_key_title)
      end
    end
  end
end
