# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User filters Alert Management table by status', :js, feature_category: :incident_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:alert1, reload: true) { create(:alert_management_alert, :triggered, project: project) }
  let_it_be(:alert2, reload: true) { create(:alert_management_alert, :acknowledged, project: project) }
  let_it_be(:alert3, reload: true) { create(:alert_management_alert, :acknowledged, project: project) }

  before do
    sign_in(developer)

    visit project_alert_management_index_path(project)
    wait_for_requests
  end

  context 'when a developer displays the alert list and the alert service is enabled they can filter the table by an alert status' do
    it 'shows the alert table items with alert status of Open by default' do
      expect(page).to have_selector('.gl-table')
      expect(page).to have_content('Open 3')
    end

    it 'shows the alert table items with alert status of Acknowledged' do
      find('.gl-tab-nav-item', text: 'Acknowledged').click

      expect(page).to have_selector('.gl-tab-nav-item-active')
      expect(find('.gl-tab-nav-item-active')).to have_content('Acknowledged 2')
      expect(all('.dropdown-menu-selectable').count).to be(2)
    end

    it 'shows the alert table items with alert status of Triggered' do
      find('.gl-tab-nav-item', text: 'Triggered').click
      wait_for_requests

      expect(page).to have_selector('.gl-tab-nav-item-active')
      expect(find('.gl-tab-nav-item-active')).to have_content('Triggered 1')
      expect(all('.dropdown-menu-selectable').count).to be(1)
    end

    it 'shows the an empty table for a status with no alerts' do
      find('.gl-tab-nav-item', text: 'Resolved').click
      wait_for_requests

      expect(page).to have_selector('.gl-tab-nav-item-active')
      expect(find('.gl-tab-nav-item-active')).to have_content('Resolved 0')
      expect(page).to have_content('No alerts to display.')
    end
  end
end
