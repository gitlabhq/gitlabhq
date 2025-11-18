# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Incident Management index', :js, feature_category: :incident_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }
  let_it_be(:guest) { create(:user, guest_of: project) }
  let_it_be(:incident) { create(:incident, project: project) }

  before do
    stub_feature_flags(hide_incident_management_features: false)
    sign_in(user)

    visit project_incidents_path(project)
  end

  describe 'incident list is visited' do
    context 'by reporter' do
      let(:user) { reporter }

      it 'when "Create incident" is clicked shows the create issue page with the Incident type pre-selected' do
        click_link 'Create incident'

        expect(page).to have_select('Type', selected: 'Incident')
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
