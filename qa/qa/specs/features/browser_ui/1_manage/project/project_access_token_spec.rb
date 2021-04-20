# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    describe 'Project access tokens' do
      let(:project_access_token) {QA::Resource::ProjectAccessToken.fabricate_via_browser_ui!}

      it 'can be created and revoked via the UI' do
        expect(project_access_token.token).not_to be_nil

        project_access_token.revoke_via_ui!
        expect(page).to have_text("Revoked project access token #{project_access_token.name}!")
      end

      after do
        project_access_token.project.remove_via_api!
      end
    end
  end
end
