# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Alert Management index', :js do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:alert) { create(:alert_management_alert, project: project, status: 'triggered') }

  before_all do
    project.add_developer(developer)
  end

  before do
    sign_in(developer)

    visit project_alert_management_index_path(project)
    wait_for_requests
  end

  context 'when a developer displays the alert list and alert integrations are not enabled' do
    it 'shows the alert page title' do
      expect(page).to have_content('Alerts')
    end

    it 'shows the empty state by default' do
      expect(page).to have_content('Surface alerts in GitLab')
    end

    it 'does not show the filtered search' do
      page.within('.layout-page') do
        expect(page).not_to have_css('[data-testid="search-icon"]')
      end
    end

    it 'does not show the alert table' do
      expect(page).not_to have_selector('.gl-table')
    end
  end

  context 'when a developer displays the alert list and an HTTP integration is enabled' do
    let_it_be(:integration) { create(:alert_management_http_integration, project: project) }

    it 'shows the alert page title' do
      expect(page).to have_content('Alerts')
    end

    it 'shows the filtered search' do
      page.within('.layout-page') do
        expect(page).to have_css('[data-testid="search-icon"]')
      end
    end

    it 'shows the alert table' do
      expect(page).to have_selector('.gl-table')
    end
  end
end
