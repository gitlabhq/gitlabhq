# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates Jira', :js, feature_category: :integrations do
  include_context 'project integration activation'
  include_context 'project integration Jira context'

  before do
    stub_request(:get, test_url).to_return(body: { key: 'value' }.to_json)
    stub_request(:get, client_url).to_return(body: { key: 'value' }.to_json)
  end

  describe 'user tests Jira integration' do
    context 'when Jira connection test succeeds' do
      before do
        visit_project_integration('Jira')
        fill_form
        click_test_then_save_integration(expect_test_to_fail: false)
      end

      it 'activates the Jira integration' do
        expect(page).to have_content('Jira issues settings saved and active.')
        expect(page).to have_current_path(edit_project_settings_integration_path(project, :jira), ignore_query: true)
      end

      unless Gitlab.ee?
        it 'adds Jira link to sidebar menu' do
          within_testid('super-sidebar') do
            click_button 'Plan'
            expect(page).not_to have_link('Jira issues')
            expect(page).not_to have_link('Open Jira')
            expect(page).to have_link(exact_text: 'Jira', href: url)
          end
        end
      end
    end

    context 'when Jira connection test fails' do
      it 'shows errors when some required fields are not filled in' do
        visit_project_integration('Jira')

        fill_in 'service-password', with: 'password'
        click_test_integration

        within_testid 'integration-settings-form' do
          expect(page).to have_content('This field is required.')
        end
      end

      it 'activates the Jira integration' do
        stub_request(:get, test_url).with(basic_auth: %w[username password])
          .to_raise(JIRA::HTTPError.new(double(message: 'message', code: '200')))
        stub_request(:get, client_url).with(basic_auth: %w[username password])
          .to_raise(JIRA::HTTPError.new(double(message: 'message', code: '200')))

        visit_project_integration('Jira')
        fill_form
        click_test_then_save_integration

        expect(page).to have_content('Jira issues settings saved and active.')
        expect(page).to have_current_path(edit_project_settings_integration_path(project, :jira), ignore_query: true)
      end
    end
  end

  describe 'user disables the Jira integration' do
    include JiraIntegrationHelpers

    before do
      stub_jira_integration_test
      visit_project_integration('Jira')
      fill_form(disable: true)
      click_save_integration
    end

    it 'saves but does not activate the Jira integration' do
      expect(page).to have_content('Jira issues settings saved, but not active.')
      expect(page).to have_current_path(edit_project_settings_integration_path(project, :jira), ignore_query: true)
    end

    it 'does not show the Jira link in the menu' do
      within_testid('super-sidebar') do
        click_button 'Plan'
        expect(page).not_to have_link('Jira')
      end
    end
  end

  describe 'issue transition settings' do
    it 'using custom transitions' do
      visit_project_integration('Jira')

      expect(page).to have_field('Enable Jira transitions', checked: false)

      check 'Enable Jira transitions'

      expect(page).to have_field('Move to Done', checked: true)

      fill_form
      choose 'Use custom transitions'
      click_save_integration

      within_testid 'issue-transition-mode' do
        expect(page).to have_content('This field is required.')
      end

      fill_in 'service[jira_issue_transition_id]', with: '1, 2, 3'
      click_save_integration

      expect(page).to have_content('Jira issues settings saved and active.')
      expect(project.reload.jira_integration.data_fields).to have_attributes(
        jira_issue_transition_automatic: false,
        jira_issue_transition_id: '1, 2, 3'
      )
    end

    it 'using automatic transitions' do
      create(:jira_integration, project: project, jira_issue_transition_automatic: false, jira_issue_transition_id: '1, 2, 3')
      visit_project_integration('Jira')

      expect(page).to have_field('Enable Jira transitions', checked: true)
      expect(page).to have_field('Use custom transitions', checked: true)
      expect(page).to have_field('service[jira_issue_transition_id]', with: '1, 2, 3')

      choose 'Move to Done'
      click_save_integration

      expect(page).to have_content('Jira issues settings saved and active.')
      expect(project.reload.jira_integration.data_fields).to have_attributes(
        jira_issue_transition_automatic: true,
        jira_issue_transition_id: ''
      )
    end

    it 'disabling issue transitions' do
      create(:jira_integration, project: project, jira_issue_transition_automatic: true, jira_issue_transition_id: '1, 2, 3')
      visit_project_integration('Jira')

      expect(page).to have_field('Enable Jira transitions', checked: true)
      expect(page).to have_field('Move to Done', checked: true)

      uncheck 'Enable Jira transitions'
      click_save_integration

      expect(page).to have_content('Jira issues settings saved and active.')
      expect(project.reload.jira_integration.data_fields).to have_attributes(
        jira_issue_transition_automatic: false,
        jira_issue_transition_id: ''
      )
    end
  end
end
