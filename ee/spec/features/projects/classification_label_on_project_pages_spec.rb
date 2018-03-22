require 'spec_helper'

describe 'Classification label on project pages' do
  let(:project) do
    create(:project, external_authorization_classification_label: 'authorized label')
  end
  let(:user) { create(:user) }

  before do
    stub_ee_application_setting(external_authorization_service_enabled: true)
    project.add_master(user)
    sign_in(user)
  end

  it 'shows the classification label on the project page when the feature is enabled' do
    stub_licensed_features(external_authorization_service: true)

    visit project_path(project)

    expect(page).to have_content('authorized label')
  end

  it 'does not show the classification label when the feature is not enabled' do
    stub_licensed_features(external_authorization_service: false)

    visit project_path(project)

    expect(page).not_to have_content('authorized label')
  end
end
