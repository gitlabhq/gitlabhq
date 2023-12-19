# frozen_string_literal: true

module QA
  RSpec.describe 'Release', product_group: :environments do
    describe 'Deploy token creation' do
      it 'user adds a deploy token', :reliable,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348028' do
        Flow::Login.sign_in

        deploy_token_name = 'deploy token name'
        one_week_from_now = Date.today + 7

        deploy_token = Resource::ProjectDeployToken.fabricate_via_api! do |resource|
          resource.name = deploy_token_name
          resource.expires_at = one_week_from_now
          resource.scopes = %w[read_repository]
        end

        expect(deploy_token.username.length).to be > 0
        expect(deploy_token.token.length).to be > 0
      end
    end
  end
end
