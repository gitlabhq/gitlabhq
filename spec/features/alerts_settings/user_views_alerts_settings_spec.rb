# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Alert integrations settings form', :js, feature_category: :incident_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:maintainer) { create(:user, maintainer_of: project) }
  let_it_be(:developer) { create(:user, developer_of: project) }

  before do
    sign_in(maintainer)
  end

  describe 'when viewing alert integrations as a maintainer' do
    context 'with the default page permissions' do
      before do
        stub_feature_flags(remove_monitor_metrics: false)
        visit project_settings_operations_path(project, anchor: 'js-alert-management-settings')
        wait_for_requests
      end

      it 'shows the alerts setting form title' do
        page.within('#js-alert-management-settings') do
          expect(find('h2.gl-heading-2')).to have_content('Alerts')
        end
      end

      it 'shows the integrations list title' do
        expect(page).to have_content('Current integrations')
      end
    end
  end

  describe 'when viewing alert integrations as a developer' do
    before do
      sign_in(developer)

      visit project_settings_operations_path(project, anchor: 'js-alert-management-settings')
      wait_for_requests
    end

    it 'does not have rights to access the setting form' do
      expect(page).not_to have_selector('.incident-management-list')
      expect(page).not_to have_selector('#js-alert-management-settings')
    end
  end
end
