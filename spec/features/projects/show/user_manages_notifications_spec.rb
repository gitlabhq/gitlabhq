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

    wait_for_requests

    click_notifications_button
    expect(find('.update-notification.is-active')).to have_content('On mention')
    expect(find('.notifications-icon use')[:'xlink:href']).to end_with('#notifications')
  end

  it 'changes the notification setting to disabled' do
    visit project_path(project)
    click_notifications_button
    click_link 'Disabled'

    wait_for_requests

    expect(find('.notifications-icon use')[:'xlink:href']).to end_with('#notifications-off')
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
        :success_pipeline
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

    context 'when ci_pipeline_fixed_notifications is disabled' do
      before do
        stub_feature_flags(ci_pipeline_fixed_notifications: false)
      end

      it 'hides fixed_pipeline checkbox' do
        visit project_path(project)
        click_notifications_button
        page.find('a[data-notification-level="custom"]').click

        expect(page).not_to have_selector("input[name='notification_setting[fixed_pipeline]']")
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
