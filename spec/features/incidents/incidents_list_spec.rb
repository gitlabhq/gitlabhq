# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Incident Management index', :js, feature_category: :incident_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:incident) { create(:incident, project: project) }

  before do
    sign_in(developer)

    visit project_incidents_path(project)
    wait_for_requests
  end

  context 'when a developer displays the incident list' do
    it 'shows the status tabs' do
      expect(page).to have_selector('.gl-tabs')
    end

    it 'shows the filtered search' do
      expect(page).to have_selector('.filtered-search-wrapper')
    end

    it 'shows the alert table' do
      expect(page).to have_selector('.gl-table')
    end

    it 'alert page title' do
      expect(page).to have_content('Incidents')
    end

    it 'has expected columns' do
      table = page.find('.gl-table')

      expect(table).to have_content('Severity')
      expect(table).to have_content('Incident')
      expect(table).to have_content('Status')
      expect(table).to have_content('Date created')
      expect(table).to have_content('Assignees')
    end
  end
end
