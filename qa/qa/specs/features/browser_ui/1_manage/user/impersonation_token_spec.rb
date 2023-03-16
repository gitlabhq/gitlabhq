# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    describe 'Impersonation tokens', :requires_admin, product_group: :authentication_and_authorization do
      let(:admin_api_client) { Runtime::API::Client.as_admin }

      let!(:user) do
        Resource::User.fabricate_via_api! do |usr|
          usr.api_client = admin_api_client
          usr.hard_delete_on_api_removal = true
        end
      end

      it(
        'can be created and revoked via the UI',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/368888'
      ) do
        impersonation_token = QA::Resource::ImpersonationToken.fabricate_via_browser_ui! do |impersonation_token|
          impersonation_token.api_client = admin_api_client
          impersonation_token.user = user
        end

        expect(impersonation_token.token).not_to be_nil

        impersonation_token.revoke_via_browser_ui!

        expect(page).to have_text("Revoked impersonation token #{impersonation_token.name}!")
      end
    end
  end
end
