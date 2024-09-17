# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User updates Alert Management status', :js, feature_category: :incident_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:alert) { create(:alert_management_alert, project: project, status: 'triggered') }

  before do
    sign_in(developer)

    visit project_alert_management_index_path(project)
    wait_for_requests
  end

  context 'when a developer+ displays the alerts list and the alert service is enabled they can update an alert status' do
    it 'shows the alert table with an alert status dropdown' do
      expect(page).to have_selector('.gl-table')
      expect(find('.dropdown-menu-selectable')).to have_content('Triggered')
    end

    it 'updates the alert status', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/444723' do
      find('.dropdown-menu-selectable').click
      find('.gl-new-dropdown-item', text: 'Acknowledged').click
      wait_for_requests

      expect(find('.dropdown-menu-selectable')).to have_content('Acknowledged')
    end
  end
end
