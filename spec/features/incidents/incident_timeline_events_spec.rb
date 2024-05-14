# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Incident timeline events', :js, feature_category: :incident_management do
  include ListboxHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, developer_of: project) }
  let_it_be(:incident) { create(:incident, project: project) }

  shared_examples 'add, edit, and delete timeline events' do
    it 'submits event data on save' do
      # Add event
      click_button(s_('Incident|Add new timeline event'))
      complete_form('Event note goes here', '07', '25')

      expect(page).to have_selector('.incident-timeline-events')
      page.within '.timeline-event-note' do
        expect(page).to have_content('Event note goes here')
        expect(page).to have_content('07:25')
      end

      # Edit event
      trigger_dropdown_action(_('Edit'))
      complete_form('Edited event note goes here', '08', '30')

      page.within '.timeline-event-note' do
        expect(page).to have_content('Edited event note goes here')
        expect(page).to have_content('08:30')
      end

      # Delete event
      trigger_dropdown_action(_('Delete'))

      page.within '.modal' do
        expect(page).to have_content(s_('Incident|Delete event'))
      end

      click_button s_('Incident|Delete event')
      wait_for_requests

      expect(page).to have_content(s_('Incident|No timeline items have been added yet.'))
    end

    it 'submits event data on save' do
      # Add event
      click_button(s_('Incident|Add new timeline event'))

      select_from_listbox('Start time', from: 'Select tags')

      complete_form('Event note goes here', '07', '25')

      expect(page).to have_selector('.incident-timeline-events')
      page.within '.timeline-event-note' do
        expect(page).to have_content('Event note goes here')
        expect(page).to have_content('07:25')
        expect(page).to have_content('Start time')
      end

      # Edit event
      trigger_dropdown_action(_('Edit'))

      select_from_listbox('Start time', from: 'Start time')

      complete_form('Edited event note goes here', '08', '30')

      page.within '.timeline-event-note' do
        expect(page).to have_content('Edited event note goes here')
        expect(page).to have_content('08:30')
        expect(page).not_to have_content('Start time')
      end
    end

    private

    def complete_form(title, hours, minutes)
      fill_in _('Description'), with: title
      fill_in 'timeline-input-hours', with: hours
      fill_in 'timeline-input-minutes', with: minutes

      click_button _('Save')
      wait_for_requests
    end

    def trigger_dropdown_action(text)
      click_button _('More actions')

      within_testid 'disclosure-content' do
        find_by_testid('disclosure-dropdown-item', text: text).click
      end
    end
  end

  it_behaves_like 'for each incident details route',
    'add, edit, and delete timeline events',
    tab_text: s_('Incident|Timeline'),
    tab: 'timeline'
end
