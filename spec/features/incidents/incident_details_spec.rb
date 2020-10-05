# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Incident details', :js do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:incident) { create(:incident, project: project, author: developer, description: 'description') }

  before_all do
    project.add_developer(developer)
  end

  before do
    sign_in(developer)

    visit project_issues_incident_path(project, incident)
    wait_for_requests
  end

  context 'when a developer+ displays the incident' do
    it 'shows the incident' do
      page.within('.issuable-details') do
        expect(find('h2')).to have_content(incident.title)
      end
    end

    it 'does not show design management' do
      expect(page).not_to have_selector('.js-design-management')
    end

    it 'shows the incident tabs' do
      page.within('.issuable-details') do
        incident_tabs = find('[data-testid="incident-tabs"]')

        expect(find('h2')).to have_content(incident.title)
        expect(incident_tabs).to have_content('Summary')
        expect(incident_tabs).to have_content(incident.description)
      end
    end

    it 'shows the right sidebar mounted with type issue' do
      page.within('.layout-page') do
        sidebar = find('.right-sidebar')

        expect(page).to have_selector('.right-sidebar[data-issuable-type="issue"]')
        expect(sidebar).to have_selector('.incident-severity')
        expect(sidebar).not_to have_selector('.milestone')
      end
    end
  end
end
