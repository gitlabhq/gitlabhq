# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Incident Management index', :js, feature_category: :incident_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }
  let_it_be(:guest) { create(:user, guest_of: project) }
  let_it_be(:incident) { create(:incident, project: project) }

  before do
    sign_in(user)

    visit project_incidents_path(project)
    wait_for_all_requests
  end

  describe 'incident list is visited' do
    context 'by reporter' do
      let(:user) { reporter }

      it 'shows the create new incident button' do
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
  end

  context 'by guest' do
    let(:user) { guest }

    it 'does not show new incident button' do
      expect(page).not_to have_selector('.create-incident-button')
    end
  end
end
