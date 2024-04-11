# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User uploads alerts to incident', :js, feature_category: :incident_management do
  let_it_be(:incident) { create(:incident) }
  let_it_be(:project) { incident.project }
  let_it_be(:user) { create(:user, developer_of: project) }

  context 'with alert' do
    let_it_be(:alert) { create(:alert_management_alert, issue_id: incident.id, project: project) }

    shared_examples 'shows alert tab with details' do
      specify do
        expect(page).to have_link(s_('Incident|Alert details'))
        expect(page).to have_content(alert.title)
      end
    end

    it_behaves_like 'for each incident details route',
      'shows alert tab with details',
      tab_text: s_('Incident|Alert details'),
      tab: 'alerts'
  end

  context 'with no alerts' do
    it 'hides the Alert details tab' do
      sign_in(user)
      visit project_issue_path(project, incident)

      expect(page).not_to have_link(s_('Incident|Alert details'))
    end
  end
end
