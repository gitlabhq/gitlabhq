# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User searches Incident Management incidents', :js, feature_category: :incident_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:incident) { create(:incident, project: project) }

  before do
    sign_in(developer)

    visit project_incidents_path(project)
    wait_for_requests
  end

  context 'when a developer displays the incident list they can search for an incident' do
    it 'shows the incident table with an incident for a valid search filter bar' do
      expect(page).to have_selector('.filtered-search-wrapper')
      expect(page).to have_selector('.gl-table')
      expect(page).to have_selector('.incident-severity')
      expect(all('tbody tr').count).to be(1)
      expect(page).not_to have_selector('.empty-state')
    end
  end
end
