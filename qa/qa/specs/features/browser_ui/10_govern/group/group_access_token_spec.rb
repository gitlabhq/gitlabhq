# frozen_string_literal: true

module QA
  RSpec.describe 'Govern' do
    describe 'Group access tokens', product_group: :authentication do
      let(:group_access_token) { QA::Resource::GroupAccessToken.fabricate_via_browser_ui! }

      it(
        'can be created and revoked via the UI', :smoke,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/367044'
      ) do
        expect(group_access_token.token).not_to be_nil

        group_access_token.revoke_via_ui!
        expect(page).to have_text("Revoked access token #{group_access_token.name}!")
      end
    end
  end
end
