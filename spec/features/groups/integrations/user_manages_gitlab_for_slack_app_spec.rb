# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User manages the group-level GitLab for Slack app integration', :js, feature_category: :integrations do
  include Spec::Support::Helpers::ModalHelpers

  include_context 'group integration activation'

  let_it_be_with_reload(:integration) do
    create(:gitlab_slack_application_integration, :group, group: group,
      slack_integration: build(:slack_integration)
    )
  end

  before do
    stub_application_setting(slack_app_enabled: true)
  end

  def visit_slack_application_form
    visit_group_integration('GitLab for Slack app')
    wait_for_requests
  end

  it 'shows the workspace name but not the alias and does not allow the user to edit it' do
    visit_slack_application_form

    within_testid 'integration-settings-form' do
      expect(page).to have_content('Workspace name')
      expect(page).to have_content(integration.slack_integration.team_name)
      expect(page).not_to have_content('Project alias')
      expect(page).not_to have_content(integration.slack_integration.alias)
      expect(page).not_to have_content('Edit')
    end
  end

  context 'when an integration is inherited' do
    let_it_be(:instance_integration) do
      create(:gitlab_slack_application_integration, :instance, slack_integration: build(:slack_integration))
    end

    before do
      integration.update!(inherit_from_id: instance_integration.id)
    end

    it 'does not allow the user to unlink the GitLab for Slack app' do
      visit_slack_application_form

      within_testid 'integration-settings-form' do
        expect(page).to have_css('a.btn-danger[disabled]')
      end
    end
  end

  context 'when an integration is not inherited' do
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
  end

  it 'shows the trigger form fields' do
    visit_slack_application_form

    expect(page).to have_selector('[data-testid="trigger-fields-group"]')
  end

  context 'when the integration is disabled' do
    before do
      Integrations::GitlabSlackApplication.for_group(group).first.update!(active: false)
    end

    it 'does not show the trigger form fields' do
      visit_slack_application_form

      expect(page).not_to have_selector('[data-testid="trigger-fields-group"]')
    end
  end
end
