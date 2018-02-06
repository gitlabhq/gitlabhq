module QA
  feature 'deploy keys support', :core do
    scenario 'user adds a deploy key' do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }

      key = Runtime::RSAKey.new
      deploy_key_title = 'deploy key title'
      deploy_key_value = key.public_key

      deploy_key = Factory::Resource::DeployKey.fabricate! do |resource|
        resource.title = deploy_key_title
        resource.key = deploy_key_value
      end

      expect(deploy_key.title).to eq(deploy_key_title)
      expect(deploy_key.fingerprint).to eq(key.fingerprint)
    end
  end
end
