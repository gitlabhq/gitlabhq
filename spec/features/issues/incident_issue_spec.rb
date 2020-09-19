# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Incident Detail', :js do
  context 'when user displays the incident' do
    it 'shows the incident tabs' do
      project = create(:project, :public)
      incident = create(:incident, project: project, description: 'hello')

      visit project_issue_path(project, incident)
      wait_for_requests

      page.within('.issuable-details') do
        incident_tabs = find('[data-testid="incident-tabs"]')

        expect(find('h2')).to have_content(incident.title)
        expect(incident_tabs).to have_content('Summary')
        expect(incident_tabs).to have_content(incident.description)
      end
    end
  end
end
