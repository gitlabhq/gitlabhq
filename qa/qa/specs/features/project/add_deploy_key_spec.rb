module QA
  feature 'deploy keys support', :core do
    given(:key) { Runtime::RSAKey.new }
    given(:deploy_key_title) { 'deploy key title' }
    given(:deploy_key_value) { key.public_key }

    scenario 'user adds a deploy key' do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }

      deploy_key = Factory::Resource::DeployKey.fabricate! do |resource|
        resource.title = deploy_key_title
        resource.key = deploy_key_value
      end

      expect(deploy_key.title).to eq(deploy_key_title)
      expect(deploy_key.fingerprint).to eq(key.fingerprint)
    end
  end
end
