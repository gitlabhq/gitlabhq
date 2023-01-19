# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Incident timeline events', :js, feature_category: :incident_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:incident) { create(:incident, project: project) }

  before_all do
    project.add_developer(developer)
  end

  before do
    sign_in(developer)

    visit project_issues_incident_path(project, incident)
    wait_for_requests
    click_link s_('Incident|Timeline')
  end

  context 'when add event is clicked' do
    it 'submits event data when save is clicked' do
      click_button s_('Incident|Add new timeline event')

      expect(page).to have_selector('.common-note-form')

      fill_in _('Description'), with: 'Event note goes here'
      fill_in 'timeline-input-hours', with: '07'
      fill_in 'timeline-input-minutes', with: '25'

      click_button _('Save')

      expect(page).to have_selector('.incident-timeline-events')

      page.within '.timeline-event-note' do
        expect(page).to have_content('Event note goes here')
        expect(page).to have_content('07:25')
      end
    end
  end

  context 'when add event is clicked and feature flag enabled' do
    before do
      stub_feature_flags(incident_event_tags: true)
    end

    it 'submits event data with tags when save is clicked' do
      click_button s_('Incident|Add new timeline event')

      expect(page).to have_selector('.common-note-form')

      fill_in _('Description'), with: 'Event note goes here'
      fill_in 'timeline-input-hours', with: '07'
      fill_in 'timeline-input-minutes', with: '25'

      click_button _('Select tags')

      page.within '.gl-dropdown-inner' do
        expect(page).to have_content(_('Start time'))
        page.find('.gl-dropdown-item-text-wrapper', text: _('Start time')).click
      end

      click_button _('Save')

      expect(page).to have_selector('.incident-timeline-events')

      page.within '.timeline-event-note' do
        expect(page).to have_content('Event note goes here')
        expect(page).to have_content('07:25')
        expect(page).to have_content('Start time')
      end
    end
  end

  context 'when edit is clicked' do
    before do
      click_button 'Add new timeline event'
      fill_in 'Description', with: 'Event note to edit'
      click_button _('Save')
    end

    it 'shows the confirmation modal and edits the event' do
      click_button _('More actions')

      page.within '.gl-dropdown-contents' do
        expect(page).to have_content(_('Edit'))
        page.find('.gl-dropdown-item-text-primary', text: _('Edit')).click
      end

      expect(page).to have_selector('.common-note-form')

      fill_in _('Description'), with: 'Event note goes here'
      fill_in 'timeline-input-hours', with: '07'
      fill_in 'timeline-input-minutes', with: '25'

      click_button _('Save')

      wait_for_requests

      page.within '.timeline-event-note' do
        expect(page).to have_content('Event note goes here')
        expect(page).to have_content('07:25')
      end
    end
  end

  context 'when edit is clicked and feature flag enabled' do
    before do
      stub_feature_flags(incident_event_tags: true)
      click_button 'Add new timeline event'
      fill_in 'Description', with: 'Event note to edit'
      click_button _('Select tags')

      page.within '.gl-dropdown-inner' do
        page.find('.gl-dropdown-item-text-wrapper', text: _('Start time')).click
      end
      click_button _('Save')
    end

    it 'shows the confirmation modal and edits the event tags' do
      click_button _('More actions')

      page.within '.gl-dropdown-contents' do
        expect(page).to have_content(_('Edit'))
        page.find('.gl-dropdown-item-text-primary', text: _('Edit')).click
      end

      expect(page).to have_selector('.common-note-form')

      click_button s_('Start time')

      page.within '.gl-dropdown-inner' do
        expect(page).to have_content(_('Start time'))
        page.find('.gl-dropdown-item-text-wrapper', text: _('Start time')).click
      end

      click_button _('Save')

      wait_for_requests

      page.within '.timeline-event-note' do
        expect(page).not_to have_content('Start time')
      end
    end
  end

  context 'when delete is clicked' do
    before do
      click_button s_('Incident|Add new timeline event')
      fill_in _('Description'), with: 'Event note to delete'
      click_button _('Save')
    end

    it 'shows the confirmation modal and deletes the event' do
      click_button _('More actions')

      page.within '.gl-dropdown-contents' do
        expect(page).to have_content(_('Delete'))
        page.find('.gl-dropdown-item-text-primary', text: 'Delete').click
      end

      page.within '.modal' do
        expect(page).to have_content(s_('Incident|Delete event'))
      end

      click_button s_('Incident|Delete event')

      wait_for_requests

      expect(page).to have_content(s_('Incident|No timeline items have been added yet.'))
    end
  end
end
