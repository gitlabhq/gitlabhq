# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates Jira', :js do
  include_context 'project service activation'
  include_context 'project service Jira context'

  before do
    stub_request(:get, test_url).to_return(body: { key: 'value' }.to_json)
  end

  describe 'user tests Jira Service' do
    context 'when Jira connection test succeeds' do
      before do
        visit_project_integration('Jira')
        fill_form
        click_test_then_save_integration(expect_test_to_fail: false)
      end

      it 'activates the Jira service' do
        expect(page).to have_content('Jira settings saved and active.')
        expect(current_path).to eq(edit_project_service_path(project, :jira))
      end

      unless Gitlab.ee?
        it 'adds Jira link to sidebar menu' do
          page.within('.nav-sidebar') do
            expect(page).not_to have_link('Jira Issues')
            expect(page).not_to have_link('Issue List', visible: false)
            expect(page).not_to have_link('Open Jira', href: url, visible: false)
            expect(page).to have_link('Jira', href: url)
          end
        end
      end
    end

    context 'when Jira connection test fails' do
      it 'shows errors when some required fields are not filled in' do
        visit_project_integration('Jira')

        fill_in 'service_password', with: 'password'
        click_test_integration

        page.within('.service-settings') do
          expect(page).to have_content('This field is required.')
        end
      end

      it 'activates the Jira service' do
        stub_request(:get, test_url).with(basic_auth: %w(username password))
          .to_raise(JIRA::HTTPError.new(double(message: 'message')))

        visit_project_integration('Jira')
        fill_form
        click_test_then_save_integration

        expect(page).to have_content('Jira settings saved and active.')
        expect(current_path).to eq(edit_project_service_path(project, :jira))
      end
    end
  end

  describe 'user disables the Jira Service' do
    include JiraServiceHelper

    before do
      stub_jira_integration_test
      visit_project_integration('Jira')
      fill_form(disable: true)
      click_save_integration
    end

    it 'saves but does not activate the Jira service' do
      expect(page).to have_content('Jira settings saved, but not active.')
      expect(current_path).to eq(edit_project_service_path(project, :jira))
    end

    it 'does not show the Jira link in the menu' do
      page.within('.nav-sidebar') do
        expect(page).not_to have_link('Jira', href: url)
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

      within '[data-testid="issue-transition-mode"]' do
        expect(page).to have_content('This field is required.')
      end

      fill_in 'service[jira_issue_transition_id]', with: '1, 2, 3'
      click_save_integration

      expect(page).to have_content('Jira settings saved and active.')
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

      expect(page).to have_content('Jira settings saved and active.')
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

      expect(page).to have_content('Jira settings saved and active.')
      expect(project.reload.jira_integration.data_fields).to have_attributes(
        jira_issue_transition_automatic: false,
        jira_issue_transition_id: ''
      )
    end
  end
end
