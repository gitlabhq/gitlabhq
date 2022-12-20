# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User filters Incident Management table by status', :js, feature_category: :incident_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user) }

  before_all do
    project.add_developer(developer)

    create_list(:incident, 2, project: project, state: 'opened')
    create(:incident, project: project, state: 'closed')
  end

  before do
    sign_in(developer)

    visit project_incidents_path(project)
    wait_for_requests
  end

  context 'when a developer displays the incident list they can filter the table by an incident status' do
    def the_page_shows_the_nav_text_with_correct_count
      expect(page).to have_selector('.gl-table')
      expect(page).to have_content('All 3')
      expect(page).to have_content('Open 2')
      expect(page).to have_content('Closed 1')
    end

    it 'shows the incident table items with incident status of Open by default' do
      expect(find('.gl-tab-nav-item-active')).to have_content('Open 2')
      expect(all('tbody tr').count).to be(2)

      the_page_shows_the_nav_text_with_correct_count
    end

    it 'shows the incident table items with incident status of Closed' do
      find('.gl-tab-nav-item', text: 'Closed').click
      wait_for_requests

      expect(find('.gl-tab-nav-item-active')).to have_content('Closed 1')
      expect(all('tbody tr').count).to be(1)

      the_page_shows_the_nav_text_with_correct_count
    end

    it 'shows the incident table items with all status' do
      find('.gl-tab-nav-item', text: 'All').click
      wait_for_requests

      expect(find('.gl-tab-nav-item-active')).to have_content('All 3')
      expect(all('[data-testid="incident-assignees"]').count).to be(3)
      expect(all('tbody tr').count).to be(3)

      the_page_shows_the_nav_text_with_correct_count
    end
  end
end
