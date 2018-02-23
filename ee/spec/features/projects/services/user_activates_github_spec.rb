require 'spec_helper'

describe 'User activates GitHub Service' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)
  end

  context 'without a license' do
    it "is excluded from the integrations index" do
      visit project_settings_integrations_path(project)

      expect(page).not_to have_link('GitHub')
    end

    it 'renders 404 when trying to access service settings directly' do
      visit edit_project_service_path(project, :github)

      expect(page).to have_gitlab_http_status(404)
    end
  end

  context 'with valid license' do
    before do
      stub_licensed_features(github_project_service_integration: true)

      visit project_settings_integrations_path(project)

      click_link('GitHub')
    end

    it 'activates service' do
      check('Active')
      fill_in "Token", with: "aaaaaaaaaa"
      fill_in "Api url", with: "https://api.github.com"
      fill_in "Owner", with: "h5bp"
      fill_in "Repository name", with: "html5-boilerplate"
      click_button('Save')

      expect(page).to have_content('GitHub activated.')
    end
  end
end
