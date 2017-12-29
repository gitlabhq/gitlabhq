module QA
  feature 'deploy keys support', :core do
    before do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }

      Factory::Resource::Project.fabricate! do |scenario|
        scenario.name = 'project-to-deploy'
        scenario.description = 'project for adding deploy key test'
      end

      Page::Menu::Side.act do
        click_repository_setting
      end
    end

    given(:deploy_key_title) { 'deploy key title' }
    given(:deploy_key_value) { Runtime::User.ssh_key }

    scenario 'user adds a deploy key' do
      Page::Project::Settings::Repository.perform do |setting|
        setting.expand_deploy_keys do |page|
          page.fill_key_title(deploy_key_title)
          page.fill_key_value(deploy_key_value)

          page.add_key
        end
      end

      Page::Project::Settings::Repository.perform do |setting|
        setting.expand_deploy_keys do |page|
          expect(page).to have_key_title(deploy_key_title)
        end
      end
    end
  end
end
