# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    describe 'Project access tokens', :reliable, feature_flag: {
      name: 'bootstrap_confirmation_modals',
      scope: :global
    } do
      let(:project_access_token) { QA::Resource::ProjectAccessToken.fabricate_via_browser_ui! }

      before do
        Runtime::Feature.enable(:bootstrap_confirmation_modals)
      end

      it(
        'can be created and revoked via the UI',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347688'
      ) do
        expect(project_access_token.token).not_to be_nil

        project_access_token.revoke_via_ui!
        expect(page).to have_text("Revoked access token #{project_access_token.name}!")
      end

      after do
        project_access_token.project.remove_via_api!
      end
    end
  end
end
