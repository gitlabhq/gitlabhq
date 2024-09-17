# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Incident Detail', :js, feature_category: :team_planning do
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

      visit incident_project_issues_path(project, incident)
      wait_for_requests
    end

    it 'shows incident and alert data' do
      page.within('.issuable-details') do
        incident_tabs = find_by_testid('incident-tabs')

        aggregate_failures 'shows title and Summary tab' do
          expect(find('h1')).to have_content(incident.title)
          expect(incident_tabs).to have_content('Summary')
          expect(incident_tabs).to have_content(incident.description)
        end

        aggregate_failures 'shows the incident highlight bar' do
          expect(incident_tabs).to have_content('Alert events: 1')
          expect(incident_tabs).to have_content('Original alert: #1')
        end

        aggregate_failures 'when on summary tab (default tab)' do
          hidden_items = find_all('.js-issue-widgets')

          # Linked Issues/MRs + comment box + emoji block
          expect(hidden_items.count).to eq(3)
          expect(hidden_items).to all(be_visible)

          edit_button = find_all('[aria-label="Edit title and description"]')
          expect(edit_button).to all(be_visible)
        end

        aggregate_failures 'shows the Alert details tab' do
          click_link 'Alert details'

          expect(incident_tabs).to have_content('"title": "Alert title"')
          expect(incident_tabs).to have_content('"yet.another": 73')

          # does not show the linked issues and notes/comment components' do
          hidden_items = find_all('.js-issue-widgets', wait: false)

          # Linked Issues/MRs and comment box are hidden on page
          expect(hidden_items.count).to eq(0)
        end
      end
    end

    context 'when on timeline events tab from issue route' do
      before do
        visit project_issue_path(project, incident)
        wait_for_requests

        click_link 'Timeline'
        wait_for_requests
      end

      it 'does not show the linked issues and notes/comment components' do
        page.within('.issuable-details') do
          hidden_items = find_all('.js-issue-widgets', wait: false)

          # Linked Issues/MRs and comment box are hidden on page
          expect(hidden_items.count).to eq(0)
        end
      end
    end
  end
end
