# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Slack application', :js, feature_category: :integrations do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, maintainer_projects: [project]) }
  let_it_be(:integration) { create(:gitlab_slack_application_integration, project: project) }
  let(:slack_application_form_path) { edit_project_settings_integration_path(project, integration) }

  before do
    stub_application_setting(slack_app_enabled: true)

    gitlab_sign_in(user)
  end

  it 'I can edit slack integration' do
    visit slack_application_form_path

    within '[data-testid="integration-settings-form"]' do
      click_link 'Edit'
    end

    fill_in 'slack_integration_alias', with: 'alias-edited'
    click_button 'Save changes'

    expect(page).to have_content('The project alias was updated successfully')

    within '[data-testid="integration-settings-form"]' do
      expect(page).to have_content('alias-edited')
    end
  end

  it 'shows the trigger form fields' do
    visit slack_application_form_path

    expect(page).to have_selector('[data-testid="trigger-fields-group"]')
  end

  context 'when the integration is disabled' do
    before do
      integration.update!(active: false)
    end

    it 'does not show the trigger form fields' do
      expect(page).not_to have_selector('[data-testid="trigger-fields-group"]')
    end
  end
end
