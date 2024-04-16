# frozen_string_literal: true

module QA
  RSpec.describe 'Release', product_group: :environments do
    describe 'Deploy key creation' do
      it 'user adds a deploy key', :smoke,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348023' do
        Flow::Login.sign_in

        key = Runtime::Key::RSA.new
        deploy_key_title = 'deploy key title'
        deploy_key_value = key.public_key

        deploy_key = Resource::DeployKey.fabricate_via_browser_ui! do |resource|
          resource.title = deploy_key_title
          resource.key = deploy_key_value
        end

        expect(deploy_key.sha256_fingerprint).to eq key.sha256_fingerprint

        Page::Project::Settings::Repository.perform do |setting|
          setting.expand_deploy_keys do |keys|
            expect(keys).to have_key(deploy_key_title, key.sha256_fingerprint)
          end
        end
      end
    end
  end
end
