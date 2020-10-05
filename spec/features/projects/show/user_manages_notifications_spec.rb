# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Show > User manages notifications', :js do
  let(:project) { create(:project, :public, :repository) }

  before do
    sign_in(project.owner)
  end

  def click_notifications_button
    first('.notifications-btn').click
  end

  it 'changes the notification setting' do
    visit project_path(project)
    click_notifications_button
    click_link 'On mention'

    page.within('.notification-dropdown') do
      expect(page).not_to have_css('.gl-spinner')
    end

    click_notifications_button
    expect(find('.update-notification.is-active')).to have_content('On mention')
    expect(page).to have_css('.notifications-icon[data-testid="notifications-icon"]')
  end

  it 'changes the notification setting to disabled' do
    visit project_path(project)
    click_notifications_button
    click_link 'Disabled'

    page.within('.notification-dropdown') do
      expect(page).not_to have_css('.gl-spinner')
    end

    expect(page).to have_css('.notifications-icon[data-testid="notifications-off-icon"]')
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
      page.find('a[data-notification-level="custom"]').click

      page.within('.custom-notifications-form') do
        email_events.each do |event_name|
          expect(page).to have_selector("input[name='notification_setting[#{event_name}]']")
        end
      end
    end
  end

  context 'when project emails are disabled' do
    let(:project) { create(:project, :public, :repository, emails_disabled: true) }

    it 'is disabled' do
      visit project_path(project)
      expect(page).to have_selector('.notifications-btn.disabled', visible: true)
    end
  end
end
