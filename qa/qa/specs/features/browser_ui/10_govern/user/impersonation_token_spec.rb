# frozen_string_literal: true

module QA
  RSpec.describe 'Govern' do
    describe 'Impersonation tokens', :requires_admin, product_group: :authentication do
      let(:admin_api_client) { Runtime::API::Client.as_admin }

      let!(:user) { create(:user, :hard_delete, api_client: admin_api_client) }

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
