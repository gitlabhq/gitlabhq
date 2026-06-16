# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Alert details', :js, feature_category: :incident_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:alert) { create(:alert_management_alert, project: project, status: 'triggered', title: 'Alert') }

  before do
    sign_in(developer)
    stub_feature_flags(hide_incident_management_features: false)

    visit details_project_alert_management_path(project, alert)
    wait_for_requests
  end

  context 'when a developer displays the alert' do
    it 'shows the alert' do
      expect(find_by_testid('page-heading')).to have_content(alert.title)
    end

    it 'shows the alert tabs' do
      within_testid('detail-layout-container') do
        alert_tabs = find_by_testid('alert-details-tabs')

        expect(alert_tabs).to have_content('Alert details')
        expect(alert_tabs).to have_content('Metrics')
        expect(alert_tabs).to have_content('Activity feed')
      end
    end

    it 'shows the right sidebar mounted with correct widgets' do
      page.within('.layout-page') do
        sidebar = find_by_testid('alert-sidebar')

        expect(sidebar).to have_selector('[data-testid="status"]')
        expect(sidebar).to have_selector('[data-testid="unassigned-users"]')
        expect(sidebar).to have_content('Triggered')
      end
    end

    it 'updates the alert todo button from the right sidebar' do
      expect(page).to have_selector('[data-testid="alert-todo-button"]')
      todo_button = find_by_testid('alert-todo-button')

      expect(todo_button['aria-label']).to eq('Add a to-do item')
      find_by_testid('alert-todo-button').click
      wait_for_requests

      expect(todo_button['aria-label']).to eq('Mark to-do items done')
    end

    it 'updates the alert status from the right sidebar' do
      within_testid('sidebar-status') do
        alert_status = find_by_testid('status')

        expect(alert_status).to have_content('Triggered')

        click_button('Edit')
        find('[role="option"]', text: 'Acknowledged').click

        wait_for_requests

        expect(alert_status).to have_content('Acknowledged')
      end
    end

    it 'updates the alert assignee from the right sidebar' do
      within_testid('alert-sidebar') do
        expect(page).to have_content('None - assign yourself')

        find_by_testid('unassigned-users').click

        wait_for_requests

        expect(find_by_testid('assigned-users')).to have_content('Sidney Jones')
      end
    end
  end
end
