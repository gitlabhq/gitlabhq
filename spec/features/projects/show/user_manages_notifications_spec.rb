# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Show > User manages notifications', :js do
  let(:project) { create(:project, :public, :repository) }

  before do
    sign_in(project.owner)
  end

  def click_notifications_button
    first('[data-testid="notification-dropdown"]').click
  end

  it 'changes the notification setting' do
    visit project_path(project)
    click_notifications_button
    click_button 'On mention'

    wait_for_requests

    click_notifications_button

    page.within first('[data-testid="notification-dropdown"]') do
      expect(page.find('.gl-new-dropdown-item.is-active')).to have_content('On mention')
      expect(page).to have_css('[data-testid="notifications-icon"]')
    end
  end

  it 'changes the notification setting to disabled' do
    visit project_path(project)
    click_notifications_button
    click_button 'Disabled'

    page.within first('[data-testid="notification-dropdown"]') do
      expect(page).to have_css('[data-testid="notifications-off-icon"]')
    end
  end

  context 'custom notification settings' do
    let(:email_events) do
      [
        :new_note,
        :new_issue,
        :reopen_issue,
        :close_issue,
        :reassign_issue,
        :issue_due,
        :new_merge_request,
        :push_to_merge_request,
        :reopen_merge_request,
        :close_merge_request,
        :reassign_merge_request,
        :merge_merge_request,
        :failed_pipeline,
        :fixed_pipeline,
        :success_pipeline,
        :moved_project
      ]
    end

    it 'shows notification settings checkbox' do
      visit project_path(project)
      click_notifications_button
      click_button 'Custom'

      wait_for_requests

      page.within('#custom-notifications-modal') do
        email_events.each do |event_name|
          expect(page).to have_selector("[data-testid='notification-setting-#{event_name}']")
        end
      end
    end
  end

  context 'when project emails are disabled' do
    let(:project) { create(:project, :public, :repository, emails_disabled: true) }

    it 'is disabled' do
      visit project_path(project)
      expect(page).to have_selector('[data-testid="notification-dropdown"] .disabled', visible: true)
    end
  end
end
