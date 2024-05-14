# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Slack application', :js, feature_category: :integrations do
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, maintainer_of: project) }
  let_it_be(:integration) { create(:gitlab_slack_application_integration, project: project) }
  let(:slack_application_form_path) { edit_project_settings_integration_path(project, integration) }

  before do
    stub_application_setting(slack_app_enabled: true)

    gitlab_sign_in(user)
  end

  def visit_slack_application_form
    visit slack_application_form_path
    wait_for_requests
  end

  it 'shows the workspace name and alias and allows the user to edit it' do
    visit_slack_application_form

    within_testid 'integration-settings-form' do
      expect(page).to have_content('Workspace name')
      expect(page).to have_content(integration.slack_integration.team_name)
      expect(page).to have_content('Project alias')
      expect(page).to have_content(integration.slack_integration.alias)

      click_link 'Edit'
    end

    fill_in 'slack_integration_alias', with: 'alias-edited'
    click_button 'Save changes'

    expect(page).to have_content('The project alias was updated successfully')

    within_testid 'integration-settings-form' do
      expect(page).to have_content('alias-edited')
    end
  end

  it 'allows the user to unlink the GitLab for Slack app' do
    visit_slack_application_form

    within_testid 'integration-settings-form' do
      page.find('a.btn-danger').click
    end

    within_modal do
      expect(page).to have_content('Are you sure you want to unlink this Slack Workspace from this integration?')
      click_button('Remove')
    end

    wait_for_requests

    expect(page).to have_content('Install GitLab for Slack app')
  end

  it 'shows the trigger form fields' do
    visit_slack_application_form

    expect(page).to have_selector('[data-testid="trigger-fields-group"]')
  end

  context 'when the integration is disabled' do
    before do
      integration.update!(active: false)
    end

    it 'does not show the trigger form fields' do
      visit_slack_application_form

      expect(page).not_to have_selector('[data-testid="trigger-fields-group"]')
    end
  end
end
