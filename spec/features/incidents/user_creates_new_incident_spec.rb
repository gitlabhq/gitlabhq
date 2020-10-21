# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Incident Management index', :js do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:incident) { create(:incident, project: project) }

  before_all do
    project.add_developer(developer)
    project.add_guest(guest)
  end

  shared_examples 'create incident form' do
    it 'shows the create new issue button' do
      expect(page).to have_selector('.create-incident-button')
    end

    it 'when clicked shows the create issue page with the Incident type pre-selected' do
      find('.create-incident-button').click
      wait_for_all_requests

      expect(page).to have_selector('.dropdown-menu-toggle')
      expect(page).to have_selector('.js-issuable-type-filter-dropdown-wrap')

      page.within('.js-issuable-type-filter-dropdown-wrap') do
        expect(page).to have_content('Incident')
      end
    end
  end

  context 'when a developer displays the incident list' do
    before do
      sign_in(developer)

      visit project_incidents_path(project)
      wait_for_all_requests
    end

    it_behaves_like 'create incident form'
  end

  context 'when a guest displays the incident list' do
    before do
      sign_in(guest)

      visit project_incidents_path(project)
      wait_for_all_requests
    end

    it_behaves_like 'create incident form'
  end
end
