# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Incident Detail', :js do
  let(:user)      { create(:user) }
  let(:project)   { create(:project, :public) }
  let(:incident)  { create(:issue, project: project, author: user, issue_type: 'incident', description: 'hello') }

  context 'when user displays the incident' do
    before do
      visit project_issue_path(project, incident)
      wait_for_requests
    end

    it 'shows the incident tabs' do
      page.within('.issuable-details') do
        incident_tabs = find('[data-testid="incident-tabs"]')

        expect(find('h2')).to have_content(incident.title)
        expect(incident_tabs).to have_content('Summary')
        expect(incident_tabs).to have_content(incident.description)
      end
    end
  end
end
