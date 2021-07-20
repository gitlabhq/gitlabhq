# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Incident Detail', :js do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:payload) do
    {
      'title' => 'Alert title',
      'start_time' => '2020-04-27T10:10:22.265949279Z',
      'custom' => {
        'alert' => {
          'fields' => %w[one two]
        }
      },
      'yet' => {
        'another' => 73
      }
    }
  end

  let_it_be(:user) { create(:user) }
  let_it_be(:started_at) { Time.now.rfc3339 }
  let_it_be(:alert) { create(:alert_management_alert, project: project, payload: payload, started_at: started_at) }
  let_it_be(:incident) { create(:incident, project: project, description: 'hello', alert_management_alert: alert) }

  context 'when user displays the incident' do
    before do
      project.add_developer(user)
      sign_in(user)

      visit project_issue_path(project, incident)
      wait_for_requests
    end

    it 'shows incident and alert data' do
      page.within('.issuable-details') do
        incident_tabs = find('[data-testid="incident-tabs"]')

        aggregate_failures 'shows title and Summary tab' do
          expect(find('h2')).to have_content(incident.title)
          expect(incident_tabs).to have_content('Summary')
          expect(incident_tabs).to have_content(incident.description)
        end

        aggregate_failures 'shows the incident highlight bar' do
          expect(incident_tabs).to have_content('Alert events: 1')
          expect(incident_tabs).to have_content('Original alert: #1')
        end

        aggregate_failures 'shows the Alert details tab' do
          click_link 'Alert details'

          expect(incident_tabs).to have_content('"title": "Alert title"')
          expect(incident_tabs).to have_content('"yet.another": 73')
        end
      end
    end
  end
end
