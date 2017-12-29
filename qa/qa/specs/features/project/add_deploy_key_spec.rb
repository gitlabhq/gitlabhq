module QA
  feature 'deploy keys support', :core do
    given(:deploy_key_title) { 'deploy key title' }
    given(:deploy_key_value) { Runtime::User.ssh_key }

    scenario 'user adds a deploy key' do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }

      Factory::Resource::DeployKey.fabricate! do |deploy_key|
        deploy_key.title = deploy_key_title
        deploy_key.key = deploy_key_value
      end

      Page::Project::Settings::Repository.perform do |setting|
        setting.expand_deploy_keys do |page|
          expect(page).to have_key_title(deploy_key_title)
        end
      end
    end
  end
end
