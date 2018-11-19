# frozen_string_literal: true

module QA
  context 'Release' do
    describe 'Deploy token creation' do
      it 'user adds a deploy token' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.act { sign_in_using_credentials }

        deploy_token_name = 'deploy token name'
        deploy_token_expires_at = Date.today + 7 # 1 Week from now

        deploy_token = Resource::DeployToken.fabricate! do |resource|
          resource.name = deploy_token_name
          resource.expires_at = deploy_token_expires_at
        end

        expect(deploy_token.username.length).to be > 0
        expect(deploy_token.password.length).to be > 0
      end
    end
  end
end
