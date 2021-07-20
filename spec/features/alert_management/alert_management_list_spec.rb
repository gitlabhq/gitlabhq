# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Alert Management index', :js do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user) }

  before_all do
    project.add_developer(developer)
  end

  context 'when a developer displays the alert list' do
    before do
      sign_in(developer)

      visit project_alert_management_index_path(project)
      wait_for_requests
    end

    it 'shows the alert page title and empty state without filtered search or alert table' do
      expect(page).to have_content('Alerts')
      expect(page).to have_content('Surface alerts in GitLab')
      expect(page).not_to have_selector('.gl-table')
      page.within('.layout-page') do
        expect(page).not_to have_css('[data-testid="search-icon"]')
      end
    end

    shared_examples 'alert page with title, filtered search, and table' do
      it 'renders correctly' do
        expect(page).to have_content('Alerts')
        expect(page).to have_selector('.gl-table')
        page.within('.layout-page') do
          expect(page).to have_css('[data-testid="search-icon"]')
        end
      end
    end

    context 'when alerts have already been created' do
      let_it_be(:alert) { create(:alert_management_alert, project: project) }

      it_behaves_like 'alert page with title, filtered search, and table'
    end

    context 'when an HTTP integration is enabled' do
      let_it_be(:integration) { create(:alert_management_http_integration, project: project) }

      it_behaves_like 'alert page with title, filtered search, and table'
    end

    context 'when the prometheus integration is enabled' do
      let_it_be(:integration) { create(:prometheus_integration, project: project) }

      it_behaves_like 'alert page with title, filtered search, and table'
    end
  end

  describe 'managed_alerts_deprecation feature flag' do
    subject { page }

    before do
      stub_feature_flags(managed_alerts_deprecation: feature_flag_value)
      sign_in(developer)

      visit project_alert_management_index_path(project)
      wait_for_requests
    end

    context 'feature flag on' do
      let(:feature_flag_value) { true }

      it { is_expected.to have_pushed_frontend_feature_flags(managedAlertsDeprecation: true) }
    end

    context 'feature flag off' do
      let(:feature_flag_value) { false }

      it { is_expected.to have_pushed_frontend_feature_flags(managedAlertsDeprecation: false) }
    end
  end
end
