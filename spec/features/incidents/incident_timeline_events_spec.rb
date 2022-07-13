# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Incident timeline events', :js do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:incident) { create(:incident, project: project) }

  before_all do
    project.add_developer(developer)
  end

  before do
    stub_feature_flags(incident_timeline: true)
    sign_in(developer)

    visit project_issues_incident_path(project, incident)
    wait_for_requests
    click_link 'Timeline'
  end

  context 'when add event is clicked' do
    it 'submits event data when save is clicked' do
      click_button 'Add new timeline event'

      expect(page).to have_selector('.common-note-form')

      fill_in 'Description', with: 'Event note goes here'
      fill_in 'timeline-input-hours', with: '07'
      fill_in 'timeline-input-minutes', with: '25'

      click_button 'Save'

      expect(page).to have_selector('.incident-timeline-events')

      page.within '.timeline-event-note' do
        expect(page).to have_content('Event note goes here')
        expect(page).to have_content('07:25')
      end
    end
  end
end
